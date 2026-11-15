# =====================================================================
# test-app-review-20261115.R -- group B of the 2026-11-11 minor-issues review, as Marcus chose it 2026-11-14/15
# (notes/decision_sheet_2026-11-11_group_b.md, "Marcus's decisions" and "Decided 11-15";
# outputs/diagnostics/groupb_20261111/decisions_20261115.json). Gates for the items that change BEHAVIOUR or carry a
# NUMBER; the copy pins are test-app-review-copy.R's AC_CHECKS_1115.
#   B19  card 4a draws the What if...? tab's measure: it reproduces diag_card4_enso_estimators.R's WHATIF row, the
#        model's ENSO r exceeds the record's at every lag (the check option (a) promised), card 4's typed facts
#   B2   his Pulse lab sentence at the defaults, and both verbs follow the sign
#   B4   a change under 1 ppm prints to one decimal; the year-to-year sentence only for the year-to-year switches
#   B7   the parameters paragraph counts the table's rows; its two named groups are the mode's
#   B11/B14  the airborne fraction as annual means, its takeaway and the pre-1900 note; the budget takeaway
#   B12  the seasonal chart follows the hemisphere and measurement controls      B15  the strip's caption years
#   B22  Build your own grays a stale result, with the note; the gray-out reaches every output that reads the run
#   B10/B17/B18  the unit notes per tab, the stacking breakpoint, the tap targets and readout baselines
# Each check is paired with a case it must reject (a POWER line or a mutant).
# =====================================================================
skip_if_no_cpp()
skip_if_no_climate()

.gb_dir <- file.path(.root, "app")
.gb_app <- local({
  withr::local_options(ccx.cpp_prebuild = FALSE)
  e <- new.env(parent = globalenv())
  sys.source(file.path(.gb_dir, "global.R"), envir = e)
  for (f in sort(list.files(file.path(.gb_dir, "R"), pattern = "[.]R$", full.names = TRUE))) sys.source(f, envir = e)
  e
})
gb_server <- function() source(file.path(.gb_dir, "server.R"), local = new.env(parent = .gb_app))$value
# testServer() renders every output with its inputs unset; the What-if growth chart then warns "No shared levels found"
# (test-app-precompute.R 10). Only that message is muffled.
gb_mock <- function(expr) {
  q <- substitute(expr)
  withCallingHandlers(eval(bquote(shiny::testServer(gb_server(), .(q)))), warning = function(w)
    if (grepl("No shared levels found", conditionMessage(w), fixed = TRUE)) invokeRestart("muffleWarning"))
}
gb_txt <- function(x) paste(unlist(x), collapse = " ")
# testServer() evaluates its code with the session as a data mask over gb_mock()'s frame, so a value can leave it only
# through an object visible from this file's environment
.gb_box <- new.env()

# ---- B19 ------------------------------------------------------------------------------------------------------------
GB_CARD4_REF <- file.path(.root, "outputs", "diagnostics", "card4_enso_estimators_20261111_hilda31fl.rds")

test_that("B19. card 4a reproduces diag_card4_enso_estimators.R's WHATIF row (n, years, sd ratio, r at lag 0 and 11)", {
  e <- .gb_app; v <- e$rv_growth_variability(); ref <- readRDS(GB_CARD4_REF)
  w <- ref$series$WHATIF
  expect_identical(as.integer(v$years), as.integer(w$year))
  expect_equal(v$model_anom, unname(w$m), tolerance = 1e-12)
  expect_equal(v$obs_anom, unname(w$o), tolerance = 1e-12)
  t0 <- ref$table[ref$table$estimator == "WHATIF" & ref$table$lag_mo == 0, ]
  expect_equal(v$ratio, t0$sd_ratio, tolerance = 1e-12)
  r0 <- function(a) stats::cor(a, e$rv_enso_annual(0L)[as.character(v$years)])
  expect_equal(c(r0(v$model_anom), r0(v$obs_anom)), c(t0$r_model, t0$r_obs), tolerance = 1e-12)
  pk <- ref$peak[ref$peak$estimator == "WHATIF", ]
  expect_identical(e$RV_GROWTH_ENSO_LAG_MO, as.integer(pk$peak_lag_obs))   # the card quotes the shared peak lag
  expect_identical(as.integer(pk$peak_lag_model), as.integer(pk$peak_lag_obs))
  expect_equal(c(v$enso$r_model, v$enso$r_obs), c(pk$r_peak_model, pk$r_peak_obs), tolerance = 1e-12)
  # POWER: GATE V's own series (the card until 11-15) is a different series with a different ratio
  g <- ref$table[ref$table$estimator == "GATEV" & ref$table$lag_mo == 0, ]
  expect_gt(abs(g$sd_ratio - v$ratio), 0.1)
})

test_that("B19. the card's window is the What if...? slider's default, as ui.R writes it", {
  ui <- ccx_code_lines(readLines(file.path(.gb_dir, "ui.R"), warn = FALSE))
  i <- grep('sliderInput\\("c_years"', ui)
  blk <- paste(ui[i:(i + 3L)], collapse = " ")
  start <- as.integer(sub('.*value[[:space:]]*=[[:space:]]*c\\(([0-9]{4}),[[:space:]]*APP_HIST_YEARS\\[2\\]\\).*', "\\1", blk))
  expect_identical(c(start, as.integer(.gb_app$APP_HIST_YEARS[2])), as.integer(.gb_app$APP_CF_YEARS_DEFAULT))
  expect_false(identical(c(1900L, as.integer(.gb_app$APP_HIST_YEARS[2])), as.integer(.gb_app$APP_CF_YEARS_DEFAULT)))   # POWER
})

test_that("B19. the model's ENSO r exceeds the record's at every lag 0-18 on the card's measure (option a's promise)", {
  e <- .gb_app; v <- e$rv_growth_variability()
  for (lag in 0:18) {
    x <- e$rv_enso_annual(lag)[as.character(v$years)]; ok <- is.finite(x)
    expect_gt(stats::cor(v$model_anom[ok], x[ok]), stats::cor(v$obs_anom[ok], x[ok]), label = sprintf("lag %d", lag))
  }
  cap <- gsub("\\s+", " ", e$rv_plot_variance()$labels$caption)   # the caption is wrapped to the panel
  expect_match(cap, "follows the ENSO index more closely than the", fixed = TRUE)
  expect_match(cap, sprintf("(%d–%d)", v$window[1], v$window[2]), fixed = TRUE)
  # POWER: the comparison can go the other way on another pairing -- the 10-15 one (N7) at lag 0, model LESS
  n7 <- readRDS(GB_CARD4_REF)$table; n7 <- n7[n7$estimator == "N7" & n7$lag_mo == 0, ]
  expect_lt(n7$r_model, n7$r_obs)
})

test_that("B19. the caption says 'where both peak' because both series' r peak at the quoted lag (Marcus 11-15)", {
  e <- .gb_app; v <- e$rv_growth_variability()
  # recomputed here from rv_enso_annual(), not read from the function's own scan
  r <- t(vapply(0:18, function(L) { x <- e$rv_enso_annual(L)[as.character(v$years)]; ok <- is.finite(x)
    c(stats::cor(v$model_anom[ok], x[ok]), stats::cor(v$obs_anom[ok], x[ok])) }, c(0, 0)))
  expect_identical(c(0:18)[which.max(r[, 1])], e$RV_GROWTH_ENSO_LAG_MO)
  expect_identical(c(0:18)[which.max(r[, 2])], e$RV_GROWTH_ENSO_LAG_MO)
  expect_identical(c(v$enso$peak_model, v$enso$peak_obs), rep(e$RV_GROWTH_ENSO_LAG_MO, 2L))
  expect_identical(e$RV_GROWTH_ENSO_SCAN_MO, 0:18)
  cap <- gsub("\\s+", " ", e$rv_plot_variance()$labels$caption)
  expect_match(cap, "averaged over the twelve months to each January, where both peak, r is +0.73", fixed = TRUE)
  # POWER: at the calendar year (lag 0) neither series peaks, so a caption quoting it could not say so
  expect_false(which.max(r[, 1]) == 1L || which.max(r[, 2]) == 1L)
})

test_that("B19. card 4's typed facts hold on the card's measure (diag_card4_whatif_residuals.R's numbers)", {
  e <- .gb_app; v <- e$rv_growth_variability()
  det <- Filter(function(c) identical(c$id, 4), e$RV_CARDS)[[1]]$detail
  F <- e$app_build_forcing("historical", e$APP_HIST_YEARS, prod_c14 = e$APP_SPIN$prod_c14)
  ann <- function(x) { a <- stats::aggregate(list(x = x), list(year = floor(F$t + 1e-9)), mean); stats::setNames(a$x, a$year) }
  res <- v$model_anom - v$obs_anom
  enso <- ann(F$enso)[as.character(v$years)]
  # "The model tends to grow faster than the record in El Niño years and slower in La Niña years": the top / bottom
  # quartile of the run's ENSO index, and the association itself
  expect_match(det, "tends to grow faster than the record in El Niño years and slower in La Niña years", fixed = TRUE)
  q <- stats::quantile(enso, c(0.25, 0.75))
  expect_gt(mean(res[enso >= q[2]]), 0); expect_lt(mean(res[enso <= q[1]]), 0)
  expect_lt(stats::cor.test(res, enso)$p.value, 0.05)
  # "The misses show no trend"
  expect_match(det, "The misses show no trend.", fixed = TRUE)
  expect_gt(stats::cor.test(res, v$years)$p.value, 0.05)
  # "three of the five largest overshoots are 1991–1993, after Pinatubo"
  top5 <- v$years[order(-res)][1:5]
  expect_identical(sum(top5 %in% 1991:1993), 3L)
  expect_match(det, "three of the five largest overshoots are 1991–1993, after Pinatubo", fixed = TRUE)
  expect_false(grepl("sooner", det, fixed = TRUE))                                  # the withdrawn reading (11-15)
  # the plain's "about two thirds" (Marcus 11-15) is the nearest simple fraction to card 4a's ratio
  pl <- Filter(function(c) identical(c$id, 4), e$RV_CARDS)[[1]]$plain
  fr <- c(`one half` = 1/2, `three fifths` = 3/5, `two thirds` = 2/3, `three quarters` = 3/4, `four fifths` = 4/5)
  expect_identical(names(fr)[which.min(abs(fr - v$ratio))], "two thirds")
  expect_match(pl, "about two thirds of the observed one", fixed = TRUE)
  expect_false(names(fr)[which.min(abs(fr - 0.864))] == "two thirds")              # POWER: GATE V's ratio is not
  # POWER: the 10-15 text's claims fail on this measure -- 1991 is not the largest, and ENSO is associated
  expect_false(v$years[which.max(res)] == 1991L)
  expect_false(grepl("sixty-six", det, fixed = TRUE))
  expect_false(grepl("What-if tab's measure", det, fixed = TRUE))
})

# ---- B2 -------------------------------------------------------------------------------------------------------------
test_that("B2. his sentence at the Pulse lab's defaults, and the verbs follow the sign", {
  gb_mock({
    session$setInputs(f_mode = "Pulse lab", f_yvar = "gmst", f_fair = FALSE, p_bg = "vvM", p_year = 2050L, p_gtc = 100L)
    expect_match(output$f_takeaway, paste("Between 100 and 250 years, the warming actually increases a little (4%),",
                                          "whereas the airborne carbon concentrations drop another 18%."), fixed = TRUE)
  })
  f <- .gb_app$app_pulse_tail
  expect_identical(f(0.96, 1.06, 100, 200),
                   "Between 100 and 200 years, the warming decreases a little (4%), whereas the airborne carbon concentrations rise 6%.")
  expect_match(f(1.002, 0.82, 100, 250), "the warming stays about the same,", fixed = TRUE)
  expect_match(f(1.25, 0.82, 100, 250), "actually increases (25%)", fixed = TRUE)   # no "a little" past the bound
  expect_false(grepl("increases", f(0.94, 0.7, 100, 250), fixed = TRUE))          # POWER: a fall never "increases"
})

# ---- B4 -------------------------------------------------------------------------------------------------------------
test_that("B4. under 1 ppm the change prints to one decimal; the year-to-year sentence only for those switches", {
  f <- .gb_app$app_ppm_small
  expect_identical(f(425.433, 425.595)[c("small", "signed1")], list(small = TRUE, signed1 = "+0.2"))
  expect_identical(f(425.433, 425.2)$signed1, "−0.2")
  expect_identical(f(425.433, 425.46)$signed1, "less than 0.1")
  expect_false(f(425.433, 419.6)$small)
  # CCX_MECHANISMS is the model's (R/mechanisms.R, sourced by global.R into the global environment)
  expect_true(all(.gb_app$APP_MECH_YEAR_TO_YEAR %in% names(get("CCX_MECHANISMS", envir = .gb_app))))
  gb_mock({
    session$setInputs(c_years = c(1850L, 2024L), c_mech = "enso")
    expect_identical(output$c_takeaway, paste("With El Niño / La Niña switched off, global-average CO₂ in 2024 changes by",
      "+0.2 ppm. This switch mostly impacts year-to-year variability rather than growth over time: see the growth-rate",
      "chart below."))
    session$setInputs(c_mech = c("enso", "volcanic"))
    expect_match(output$c_takeaway, "changes by +0.4 ppm. These switches mostly impact year-to-year", fixed = TRUE)
    session$setInputs(c_mech = "revelle")                                           # POWER: a large change keeps A2's form
    expect_match(output$c_takeaway, "would be 411 ppm instead of 425", fixed = TRUE)
    expect_false(grepl("mostly impact", output$c_takeaway, fixed = TRUE))
  })
})

# ---- B7 -------------------------------------------------------------------------------------------------------------
test_that("B7. the parameters paragraph counts the table and names the mode's held groups", {
  e <- .gb_app; tab <- e$app_param_table_live()
  txt <- e$app_params_intro()
  expect_match(txt, sprintf("fits (%d) and the ones it holds at a stated value (%d).", sum(tab$Set == "fitted"),
                            sum(tab$Set == "held")), fixed = TRUE)
  expect_identical(e$app_params_intro_problems(), character(0))
  # mutants: a held value moved off zero joins the fixed group; a separate-step name released
  vals <- e$APP_PARAMS; vals$w_vent <- 3
  expect_match(e$app_params_intro_problems(values = vals), "held at a value other than 0", all = FALSE)
  expect_match(e$app_params_intro_problems(module = c("lag_enso_land", "w_enso_l2")), "the separate step fits", all = FALSE)
  expect_error(e$app_params_intro(problems = "x"), "app_params_intro")
})

# ---- B11 / B14 ----------------------------------------------------------------------------------------------------
test_that("B14/B11. the airborne fraction is annual means of full years; its takeaway, the pre-1900 note, the budget", {
  e <- .gb_app
  pt <- e$partition_table(e$APP_HIST$out, e$app_build_forcing("historical", e$APP_HIST_YEARS, prod_c14 = e$APP_SPIN$prod_c14))
  a <- e$app_af_annual(pt)
  expect_equal(min(a$year), 1755)                            # the first full year past the old 1 GtC floor
  # proto_b14.log (11-11): the annual-mean ratio's year-to-year change stays below 2 points from 1754 on, 0.5 from 1959
  expect_lt(max(abs(diff(a$af))), 0.02)
  expect_lt(max(abs(diff(a$af[a$year >= 1958]))), 0.005)
  m <- pt[pt$emitted > e$AF_MIN_EMITTED_GTC & floor(pt$t + 1e-9) == 1760, ]
  expect_gt(diff(range(m$atmosphere / m$emitted)), 0.1)      # POWER: the monthly ratio swings >10 points within 1760
  expect_identical(e$app_af_early_note(), "The airborne fraction is poorly defined before the 20th century because human emissions were small.")
  expect_match(e$app_af_early_note(2000L), "21st century", fixed = TRUE)
  gb_mock({
    session$setInputs(w_years = c(1850L, 2024L))
    expect_identical(output$w_af_takeaway, paste("About 41% of all the carbon emitted since 1750 is still in the air.",
                                                 "Since 1850 that share has stayed between 32% and 41%."))
    expect_match(gb_txt(output$w_af_note), "poorly defined before the 20th century", fixed = TRUE)
    session$setInputs(w_years = c(1900L, 2024L))
    expect_false(grepl("poorly defined", gb_txt(output$w_af_note), fixed = TRUE))
    .gb_box$gcb <- output$w_gcb_takeaway                          # checked below against the bars' own table
  })
  gcb_txt <- .gb_box$gcb
  v <- e$app_gcb_bar_values(e$APP_HIST$out, e$APP_GCB, e$app_build_forcing("historical", e$APP_HIST_YEARS,
                                                                            prod_c14 = e$APP_SPIN$prod_c14))
  expect_match(gcb_txt, sprintf("the model's ocean takes up %.2f GtC a year and the Global Carbon Budget's %.2f",
                                v$gtc[1], v$gtc[2]), fixed = TRUE)
})

# ---- B12 / B15 ----------------------------------------------------------------------------------------------------
test_that("B12. the seasonal chart follows Hemisphere and Show measurements; B15. the strip's caption names its years", {
  e <- .gb_app
  lv <- function(...) levels(e$plot_seasonal(e$APP_HIST$out, e$APP_OBS, e$APP_SEAS_WINDOW, ...)$data$who)
  expect_identical(lv("SH", TRUE), c("Model, Southern Hemisphere", "Measured, South Pole"))
  expect_identical(lv("NH", TRUE), c("Model, Northern Hemisphere", "Measured, Mauna Loa"))
  expect_length(lv("both", TRUE), 4L)
  expect_identical(lv("both", FALSE), c("Model, Northern Hemisphere", "Model, Southern Hemisphere"))
  srv <- paste(readLines(file.path(.gb_dir, "server.R")), collapse = "\n")
  expect_match(srv, "APP_SEAS_WINDOW,\n\\s+input\\$k_hemi, input\\$k_obs\\)")
  # the What-if window at its default (1850-2024) cut to the record by the caller? No: passed whole, the strip still
  # names only the years it draws -- the caption read "Same years ... as the panel above" (the growth chart's 1850)
  p <- e$plot_growth_resid(e$APP_HIST$out, NULL, e$APP_OBS_GROWTH, c(1850, 2024))
  expect_match(p$labels$caption, "The years with measurements (1980–2024)", fixed = TRUE)
  q <- e$plot_growth_resid(e$APP_HIST$out, NULL, e$APP_OBS_GROWTH, c(1990, 2010))
  expect_match(q$labels$caption, "(1990–2010)", fixed = TRUE)                     # POWER: another window, other years
})

# ---- B22 ------------------------------------------------------------------------------------------------------------
gb_readers <- function(fn) {
  ex <- parse(file.path(.gb_dir, "server.R")); b <- body(eval(ex[[length(ex)]]))
  out <- character(0)
  walk <- function(x) {
    if (is.call(x)) {
      if (identical(x[[1]], as.name("<-")) && is.call(x[[2]]) && identical(x[[2]][[1]], as.name("$")) &&
          identical(x[[2]][[2]], as.name("output")) && fn %in% all.names(x[[3]]))
        out <<- c(out, as.character(x[[2]][[3]]))
      for (a in as.list(x)[-1]) if (!missing(a)) walk(a)
    }
  }
  walk(b); unique(out)
}

test_that("B22. the gray-out reaches every output that reads the Build-your-own run", {
  expect_setequal(gb_readers("stylised_run"), .gb_app$APP_BUILD_RESULT_IDS)
  expect_true(all(gb_readers("stylised_bg_run") %in% .gb_app$APP_BUILD_RESULT_IDS))
  srv <- paste(readLines(file.path(.gb_dir, "server.R")), collapse = "\n")
  expect_match(srv, "union(APP_PULSE_RESULT_IDS, APP_BUILD_RESULT_IDS)", fixed = TRUE)
  expect_identical(.gb_app$APP_BUILD_STALE_NOTE, "Chart reflects previous settings. Press Run it to update.")
  # POWER: the two modes' sets differ, so the pulse list alone could not have covered Build your own
  expect_false(setequal(.gb_app$APP_PULSE_RESULT_IDS, .gb_app$APP_BUILD_RESULT_IDS))
})

test_that("B22. Build your own: stale once the pathway differs from the run on screen, not for a hidden slider", {
  gb_mock({
    session$setInputs(f_mode = "Build your own", f_yvar = "co2_ppm", s_kind = "constant", s_bg = "vvM",
                      s_zero_year = 2060, s_rate = 1)
    expect_false(build_stale())                                   # nothing run yet: nothing on screen to be stale
    session$setInputs(s_go = 1L)
    expect_false(build_stale())
    session$setInputs(s_kind = "rate")
    expect_true(build_stale())
    expect_match(gb_txt(output$s_stale_note), "Chart reflects previous settings. Press Run it to update.", fixed = TRUE)
    .gb_box$byo_csv <- readLines(output$f_plot_csv)               # the chart's download carries the note while grayed
    session$setInputs(s_kind = "constant")
    expect_false(build_stale())
    session$setInputs(s_rate = 3)                                 # hidden under "constant": the run would not change
    expect_false(build_stale())
    session$setInputs(s_bg = "vvH")
    expect_true(build_stale())
    session$setInputs(f_mode = "Scenarios")                       # outside the pill: not grayed
    expect_false(build_stale())
  })
  expect_true(any(grepl(.gb_app$APP_BUILD_STALE_NOTE, .gb_box$byo_csv, fixed = TRUE)))
})

# ---- UI: B10, B16/B22 script, B17, B18 ------------------------------------------------------------------------------
gb_html <- local({
  html <- NULL
  function() {
    if (is.null(html)) {
      ui <- source(file.path(.gb_dir, "ui.R"), local = new.env(parent = .gb_app), chdir = TRUE)$value
      req <- new.env(); req$QUERY_STRING <- ""
      html <<- as.character(htmltools::renderTags(ui(req))$html)
    }
    html
  }
})
gb_tab <- function(html, title) {   # the HTML of one tab pane, by its navbar title
  parts <- strsplit(html, '<div class="tab-pane', fixed = TRUE)[[1]][-1]   # [1] is the navbar, which names every tab
  own <- sub(">.*", "", parts)                                              # each pane's own opening tag
  hit <- parts[grepl(sprintf('data-value="%s"', title), own, fixed = TRUE)]
  if (length(hit) != 1L) stop("gb_tab: ", length(hit), " panes titled ", title)
  hit
}

test_that("B10. each tab that prints a unit carries its note", {
  html <- gb_html()
  has <- function(tab, s) grepl(s, gb_tab(html, tab), fixed = TRUE)
  expect_true(has("Isotope fingerprints", "Isotope ratios are given in"))
  expect_true(has("What if…?", "Carbon is measured in"))
  expect_true(has("Under the hood", "Isotope ratios are given in"))
  expect_true(has("Under the hood", "CO₂ is measured in"))
  expect_true(has("Build your own", "Carbon is measured in"))                     # the pill (its own pane)
  expect_false(has("The Keeling Curve", "Isotope ratios are given in"))            # POWER: only where ‰ is printed
})

test_that("B16/B22. the press grays the chart at once and labels it; phones scroll to the takeaway after", {
  html <- gb_html(); js <- .gb_app$APP_CALC_LABEL
  ui_txt <- paste(readLines(file.path(.gb_dir, "ui.R")), collapse = "\n")
  ue <- new.env(); for (x in parse(text = ui_txt)) if (is.call(x) && identical(as.character(x[[1]]), "<-") &&
    is.name(x[[2]]) && as.character(x[[2]]) %in% c("APP_PHONE_MAX_PX", "APP_CALC_TIMEOUT_MS", "APP_CALC_JS")) eval(x, ue)
  calc <- ue$APP_CALC_JS
  for (s in c("'#s_go, #p_go'", "addClass('ccx-calc')", "shiny:value shiny:error", "e.name === 'f_plot'", "shiny:idle",
              "(max-width: 575.98px)", "getElementById('f_takeaway')", "scrollTo"))
    expect_true(grepl(s, calc, fixed = TRUE), info = s)
  expect_match(html, '<div id="f_calc" class="ccx-calc-label" role="status" aria-live="polite">Calculating…</div>',
               fixed = TRUE)
  expect_true(grepl(".ccx-calc { opacity: 0.35; filter: grayscale(100%); }", ui_txt, fixed = TRUE))
  expect_true(grepl("tags$script(HTML(APP_CALC_JS))", ui_txt, fixed = TRUE))
})

test_that("B17/B18. the stacking rule is one block at 991.98 px; tap targets and readout baselines", {
  ui_txt <- paste(readLines(file.path(.gb_dir, "ui.R")), collapse = "\n")
  ue <- new.env()
  for (x in parse(text = ui_txt)) if (is.call(x) && identical(as.character(x[[1]]), "<-") && is.name(x[[2]]) &&
    as.character(x[[2]]) %in% c("APP_PHONE_MAX_PX", "APP_PHONE_PLOT_MIN_PX", "APP_PHONE_NARROW_PX", "APP_STACK_MAX_PX",
                                "APP_TAP_MIN_PX", "stack_css", "tidy_css")) eval(x, ue)
  expect_match(ue$stack_css, "@media (max-width: 991.98px)", fixed = TRUE)
  expect_match(ue$stack_css, ".row > [role='main'] { display: contents; }", fixed = TRUE)
  expect_match(ue$stack_css, ".row > div:has(> form.well[role='complementary']) { flex: 0 0 100%;", fixed = TRUE)
  expect_identical(lengths(regmatches(ui_txt, gregexpr("display: contents", ui_txt, fixed = TRUE))), 1L)   # one place
  expect_match(ue$tidy_css, "@media (pointer: coarse)", fixed = TRUE)
  expect_match(ue$tidy_css, "min-height: 32px", fixed = TRUE)
  html <- gb_html()
  expect_identical(lengths(regmatches(html, gregexpr('class="row ccx-readouts"', html, fixed = TRUE))), 1L)  # Where's
  srv <- paste(readLines(file.path(.gb_dir, "server.R")), collapse = "\n")
  expect_match(srv, 'fluidRow(class = "ccx-readouts"', fixed = TRUE)                                        # regrowth
})

# ---- B9: the small items that carry a computed form -------------------------------------------------------------------
test_that("B9.6. card 8's caption: true minus signs and the range low to high", {
  cap <- .gb_app$rv_plot_oclim()$labels$caption
  x <- .gb_app$rv_ocean_climate()$effect$ccx
  expect_match(cap, sprintf("(%s to %s across", .gb_app$rv_signed("%.2f", x[["min"]]), .gb_app$rv_signed("%.2f", x[["max"]])),
               fixed = TRUE)
  expect_lt(x[["min"]], x[["max"]])
  expect_false(grepl("-0.", cap, fixed = TRUE))                                     # no hyphen-minus left
})
