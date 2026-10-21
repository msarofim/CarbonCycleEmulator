# =====================================================================
# Gate: the app's PRECOMPUTED start-up runs and pulse-lab default (2026-10-20; CHANGELOG 2026-10-20 c).
#
# data/app_startup_precompute.rds (the spin-up, the historical run, the flux trace) and
# data/pulse_default_precompute.rds (the default pulse's three runs and its ocean-by-depth split) store
# what app/global.R computes at the canonical; calibration/build_app_precompute.R makes them. The
# pattern is test-review-precompute.R's. They can go stale three ways:
#   (1) an ADOPTION that does not rebuild them. The app refuses them on the md5 (and computes live, as
#       before); test 1 FAILS rather than skips, so the suite says so.
#   (2) a change to a run INPUT (the parameter resolution, the years, the pulse settings): refused on
#       app_pre_inputs(), compared identical; test 1 again.
#   (3) a CODE or DATA change that moves a value at the same inputs. Tests 2-3 recompute every value
#       live and require IDENTITY: the same functions on the same inputs, so an identity gate, exact.
# The pulse default is SERVED only when every pulse-lab input equals its default. Tests 7-9 make that
# check impossible to leave an input out of: every input the computation reads must be one the check
# covers, and each is perturbed in turn. Tests 4-8 are mutation tests: each breaks what it guards on
# purpose and requires the check to notice. Test 10 runs the real server (shiny::testServer), including
# the display Marcus ruled 2026-10-20: the default drawn with no click, the result grayed out when a
# pulse setting changes, computed on the click; test 11 checks the gray-out reaches every output.
# =====================================================================
skip_if_no_cpp()
skip_if_no_climate()

# One other valid value per pulse-lab input (each inside the controls' ranges). ⚠ Must name every
# input in APP_PULSE_DEFAULTS: test 7 fails until a new input gets one here.
APRE_PERTURB <- list(p_bg = "vvH", p_year = 2060, p_gtc = 200)
APRE_POWER_REL <- 1e-12     # one stored number moved by this much (relative) must break identity

#' The app, LIVE: global.R with the products off and no background build, plus app/R/ (as Shiny loads it)
apre_live_app <- function() {
  withr::local_options(ccx.app_precompute = FALSE, ccx.cpp_prebuild = FALSE)
  e <- new.env(parent = globalenv())
  sys.source(file.path(.root, "app", "global.R"), envir = e)
  for (f in sort(list.files(file.path(.root, "app", "R"), pattern = "[.]R$", full.names = TRUE)))
    sys.source(f, envir = e)
  e
}
.app <- apre_live_app()
.pre <- lapply(.app$APP_PRE_FILES, function(p) readRDS(do.call(file.path, c(list(.root), as.list(p)))))
.defaults <- .app$APP_PULSE_DEFAULTS

test_that("1. both products exist, are the canonical's, and are accepted at this build's run inputs", {
  for (product in names(.app$APP_PRE_FILES)) {
    x <- .pre[[product]]
    expect_identical(.app$app_pre_problems(x, product), character(0), info = product)
    expect_identical(x$provenance$rng, "none", info = product)
    expect_identical(x$provenance$keys, .app$APP_PRE_KEYS[[product]], info = product)
    expect_identical(names(x$values), .app$APP_PRE_KEYS[[product]], info = product)
    expect_false(grepl("^/", x$provenance$mode_file), info = product)   # repo-relative: ships publicly
  }
  expect_identical(.app$app_params$source, "posterior mode")   # the products are only built on the mode
})

test_that("2. the stored start-up values are what the live computation returns now", {
  v <- .pre$startup$values
  expect_identical(v$spin, .app$APP_SPIN)
  expect_identical(v$hist, .app$APP_HIST)
  expect_identical(v$flux, .app$APP_FLUX)
  # the comparison has power at roundoff: one stored number moved by APRE_POWER_REL is caught
  m <- v$hist; m$out$co2_NH[100] <- m$out$co2_NH[100] * (1 + APRE_POWER_REL)
  expect_false(identical(m, .app$APP_HIST))
})

test_that("3. the stored default pulse is the live one, and it is what the app serves for the defaults", {
  withr::local_options(ccx.app_precompute = FALSE)
  live <- .app$app_pulse_runs(.defaults)
  depth <- .app$app_pulse_depth_runs(.app$APP_SPIN, live[c("base", "pulse", "tagged")], live$year)
  expect_identical(.pre$pulse$values$runs, live)
  expect_identical(.pre$pulse$values$depth, depth)
  m <- depth; m$pulse$deep_C[50] <- m$pulse$deep_C[50] * (1 + APRE_POWER_REL)
  expect_false(identical(m, depth))
  # SERVED: the product on, read fresh -- the live runs plus the live split, bit for bit
  withr::local_options(ccx.app_precompute = TRUE)
  rm(list = ls(.app$APP_PRE_PULSE), envir = .app$APP_PRE_PULSE)
  expect_identical(.app$app_pulse_lab(.defaults), c(live, list(depth = depth)))
})

test_that("4. MUTATION: the refusal check rejects another mode, another md5, a missing key, every changed input", {
  mf <- ccx_mode_file()
  bump <- function(v) {          # the smallest change to one input's value that still reads as the same type
    if (is.list(v)) { v[[1]] <- bump(v[[1]]); v } else if (is.numeric(v)) v + pmax(abs(v), 1) * 1e-12
    else if (is.character(v)) paste0(v, "_x") else if (is.logical(v)) !v else stop("no bump for ", class(v)[1])
  }
  for (product in names(.pre)) {
    x <- .pre[[product]]
    m <- x; m$provenance$mode <- paste0(CCX_MODE_CANONICAL, "_old")
    expect_match(.app$app_pre_problems(m, product, mf), "not the canonical", info = product)
    m <- x; m$provenance$mode_md5 <- strrep("0", 32)
    expect_match(.app$app_pre_problems(m, product, mf), "md5", info = product)
    expect_match(.app$app_pre_problems(x, product, tempfile()), "md5", info = product)   # mode file absent
    k <- .app$APP_PRE_KEYS[[product]][1]
    m <- x; m$values[[k]] <- NULL
    expect_match(.app$app_pre_problems(m, product, mf), paste("lacks", k), info = product)
    for (n in names(.app$app_pre_inputs(product))) {
      m <- x; m$inputs[[n]] <- bump(m$inputs[[n]])
      p <- .app$app_pre_problems(m, product, mf)
      expect_length(p, 1L)
      expect_match(p, paste0("other run inputs: ", n, "$"), info = paste(product, n))
    }
  }
})

test_that("5. MUTATION: app_pre_read() serves an accepted product, refuses a broken one, and obeys the option", {
  withr::local_options(ccx.app_precompute = TRUE)
  good <- do.call(file.path, c(list(.root), as.list(.app$APP_PRE_FILES$startup)))
  expect_identical(.app$app_pre_read("startup", good), .pre$startup$values)
  bad <- tempfile(fileext = ".rds"); m <- .pre$startup; m$provenance$mode_md5 <- strrep("0", 32)
  saveRDS(m, bad)
  expect_message(r <- .app$app_pre_read("startup", bad), "refused")
  expect_null(r)
  expect_message(r <- .app$app_pre_read("startup", tempfile()), "no precomputed")
  expect_null(r)
  withr::local_options(ccx.app_precompute = FALSE)
  expect_null(.app$app_pre_read("startup", good))
})

test_that("6. MUTATION: app_pulse_lab() serves the stored default without computing; computes otherwise", {
  sentinel <- list(base = "stored", depth = "stored depth")
  calls <- 0L
  e <- new.env(parent = .app)    # app_pulse_lab() rebound here, so the mocks below shadow the app's
  lab <- .app$app_pulse_lab; environment(lab) <- e
  e$app_pulse_runs <- function(inp) { calls <<- calls + 1L; "live" }
  e$app_pulse_default_result <- function() sentinel
  expect_identical(lab(.defaults), sentinel)
  expect_identical(calls, 0L)
  for (n in names(APRE_PERTURB)) {
    inp <- .defaults; inp[[n]] <- APRE_PERTURB[[n]]
    expect_identical(lab(inp), "live", info = n)
  }
  expect_identical(calls, length(APRE_PERTURB))
  e$app_pulse_default_result <- function() NULL     # absent, refused or switched off
  expect_identical(lab(.defaults), "live")
  # and the accessor is the stored product in app_pulse_runs()'s shape, or NULL when there is none
  withr::local_options(ccx.app_precompute = TRUE)
  rm(list = ls(.app$APP_PRE_PULSE), envir = .app$APP_PRE_PULSE)
  expect_identical(.app$app_pulse_default_result(), c(.pre$pulse$values$runs, list(depth = .pre$pulse$values$depth)))
  withr::local_options(ccx.app_precompute = FALSE)
  expect_null(.app$app_pulse_default_result())
})

test_that("7. MUTATION: the default-match check notices EVERY pulse input; leave one out and it does not", {
  expect_setequal(names(APRE_PERTURB), names(.defaults))
  # the inputs whose change the check misses
  missed <- function(is_def) names(.defaults)[vapply(names(.defaults), function(n) {
    inp <- .defaults; inp[[n]] <- APRE_PERTURB[[n]]; isTRUE(is_def(inp)) }, logical(1))]
  expect_true(.app$app_pulse_is_default(.defaults))
  expect_identical(missed(.app$app_pulse_is_default), character(0))
  for (n in names(.defaults)) {     # the mutant: a check written without input n
    keep <- setdiff(names(.defaults), n)
    mutant <- function(inp) .app$app_pulse_is_default(inp[keep], .defaults[keep])
    expect_identical(missed(mutant), n, info = n)
  }
  # what a session sends: a slider's integer is the default's double; a missing or an extra input is not
  sess <- list(p_bg = "vvM", p_year = 2050L, p_gtc = 100L)
  expect_true(.app$app_pulse_is_default(.app$app_pulse_inputs(sess)))
  expect_false(.app$app_pulse_is_default(.defaults[-1]))
  expect_false(.app$app_pulse_is_default(c(.defaults, list(p_extra = 1))))
  # THE GRAY-OUT CHECK (2026-10-20), same power: a change to ANY input marks the result on screen stale
  stale_missed <- function(st) names(.defaults)[vapply(names(.defaults), function(n) {
    inp <- .defaults; inp[[n]] <- APRE_PERTURB[[n]]; !isTRUE(st(.defaults, inp)) }, logical(1))]
  expect_identical(stale_missed(.app$app_pulse_stale), character(0))
  expect_false(.app$app_pulse_stale(.defaults, .defaults))
  expect_false(.app$app_pulse_stale(NULL, .defaults))          # nothing on screen: nothing to gray
  for (n in names(.defaults)) {     # the mutant: a stale check written without input n
    keep <- setdiff(names(.defaults), n)
    mutant <- function(a, b) .app$app_pulse_stale(a[keep], b[keep])
    expect_identical(stale_missed(mutant), n, info = n)
  }
})

# The names an expression reads off `obj` as obj$name or obj[["name"]]
apre_names_read <- function(expr, obj) {
  out <- character(0)
  walk <- function(x) {
    if (is.call(x)) {
      if ((identical(x[[1]], as.name("$")) || identical(x[[1]], as.name("[["))) &&
          identical(x[[2]], as.name(obj)))
        out <<- c(out, as.character(x[[3]]))
      for (a in as.list(x)[-1]) if (!missing(a)) walk(a)
    }
  }
  walk(expr)
  unique(out)
}
# The server function's body (server.R's last value is the server function; test-review-cards.R)
apre_server_body <- function(lines) { ex <- parse(text = lines); body(eval(ex[[length(ex)]])) }
# Every call to one of `fns` inside an expression
apre_calls <- function(expr, fns) {
  out <- list()
  walk <- function(x) {
    if (is.call(x)) {
      if (is.name(x[[1]]) && as.character(x[[1]]) %in% fns) out[[length(out) + 1L]] <<- x
      for (a in as.list(x)[-1]) if (!missing(a)) walk(a)
    }
  }
  walk(expr)
  out
}
# The right-hand side of `name <- ...` in an expression (NULL if absent)
apre_rhs <- function(expr, name) {
  found <- NULL
  walk <- function(x) {
    if (is.call(x)) {
      if (identical(x[[1]], as.name("<-")) && identical(x[[2]], as.name(name))) found <<- x[[3]]
      for (a in as.list(x)[-1]) if (!missing(a)) walk(a)
    }
  }
  walk(expr)
  found
}
APRE_PULSE_FNS <- c("app_pulse_lab", "app_pulse_runs", "app_pulse_is_default", "app_pulse_stale")
#' What the server's pulse wiring breaks: inputs read outside APP_PULSE_DEFAULTS (character(0) if none)
apre_wiring_problems <- function(lines) {
  b <- apre_server_body(lines); bad <- character(0)
  if (!identical(apre_rhs(b, "pulse_inputs"), quote(reactive(app_pulse_inputs(input)))))
    bad <- c(bad, "pulse_inputs is not reactive(app_pulse_inputs(input))")
  for (cl in apre_calls(b, APRE_PULSE_FNS)) {
    r <- apre_names_read(as.call(c(as.name("{"), as.list(cl)[-1])), "input")
    if (length(r)) bad <- c(bad, sprintf("%s() is handed input$%s", as.character(cl[[1]]), r))
  }
  clicks <- Filter(function(cl) identical(cl[[2]], quote(input$p_go)), apre_calls(b, "observeEvent"))
  if (length(clicks) != 1L) bad <- c(bad, "not exactly one observeEvent(input$p_go, ...)")
  bad
}

test_that("8. MUTATION: the pulse computation reads only inputs the check covers (static)", {
  expect_setequal(apre_names_read(body(.app$app_pulse_runs), "inp"), names(.defaults))
  srv <- readLines(file.path(.root, "app", "server.R"), warn = FALSE)
  expect_identical(apre_wiring_problems(srv), character(0))
  expect_gte(length(apre_calls(apre_server_body(srv), APRE_PULSE_FNS)), 3L)   # the checks below have targets
  # mutant 1: the computation reads a control the defaults do not name
  b <- body(.app$app_pulse_runs); b <- as.call(c(as.list(b), quote(inp$p_dur)))
  expect_false(setequal(apre_names_read(b, "inp"), names(.defaults)))
  # mutant 2: the click hands the computation an input of its own
  srv2 <- sub("app_pulse_lab(inp)", "app_pulse_lab(c(inp, list(p_dur = input$p_dur)))", srv, fixed = TRUE)
  expect_false(identical(srv2, srv))
  expect_match(apre_wiring_problems(srv2), "app_pulse_lab\\(\\) is handed input\\$p_dur")
  # mutant 3: the inputs reactive grows a control of its own
  srv3 <- sub("reactive(app_pulse_inputs(input))",
              "reactive(c(app_pulse_inputs(input), list(p_dur = input$p_dur)))", srv, fixed = TRUE)
  expect_false(identical(srv3, srv))
  expect_match(apre_wiring_problems(srv3), "pulse_inputs is not")
})

#' The value each pulse-lab control opens on in ui.R, evaluated in the app
apre_ui_defaults <- function(lines, env) {
  out <- list()
  walk <- function(x) {
    if (is.call(x)) {
      f <- as.character(x[[1]])[1]
      if (f %in% c("sliderInput", "selectInput") && length(x) > 1L && is.character(x[[2]]) &&
          x[[2]] %in% names(.defaults)) {
        mc <- match.call(get(f, envir = asNamespace("shiny")), x)
        v <- eval(mc[[if (f == "sliderInput") "value" else "selected"]], env)
        out[[x[[2]]]] <<- if (is.numeric(v)) as.numeric(v) else v
      }
      for (a in as.list(x)[-1]) if (!missing(a)) walk(a)
    }
  }
  for (e in parse(text = lines)) walk(e)
  out[names(.defaults)]
}

test_that("9. MUTATION: ui.R opens the pulse lab ON the defaults (else the product is never served)", {
  ui <- readLines(file.path(.root, "app", "ui.R"), warn = FALSE)
  expect_identical(apre_ui_defaults(ui, .app), .defaults)
  ui2 <- sub("APP_PULSE_GtC_DEFAULT, step", "APP_PULSE_GtC_DEFAULT + 10, step", ui, fixed = TRUE)
  expect_false(identical(ui2, ui))
  expect_false(identical(apre_ui_defaults(ui2, .app), .defaults))
})

test_that("10. the real server: the default drawn with no click, grayed on a change, computed on the click", {
  skip_if_not_installed("shiny")
  srv_fn <- function() source(file.path(.root, "app", "server.R"), local = new.env(parent = .app))$value
  # ⚠ The mock session renders EVERY output, hidden tabs included, with their inputs unset. One of
  # them, the What-if tab's `c_growth`, then raises ggplot's "No shared levels found" (attributed
  # 2026-10-20 from the call stack). The pulse lab's own plots build without it (checked with FaIR on
  # and off), and the real app's log has none. Only that message is muffled.
  mock <- function(product_on, expr) {  # testServer() quotes its code, so it is forwarded quoted
    q <- substitute(expr)
    withr::local_options(ccx.app_precompute = product_on)
    rm(list = ls(.app$APP_PRE_PULSE), envir = .app$APP_PRE_PULSE)
    withCallingHandlers(eval(bquote(shiny::testServer(srv_fn(), .(q)))), warning = function(w)
      if (grepl("No shared levels found", conditionMessage(w), fixed = TRUE)) invokeRestart("muffleWarning"))
  }
  stored <- c(.pre$pulse$values$runs, list(depth = .pre$pulse$values$depth))
  on <- new.env(); off <- new.env()
  mock(TRUE, {
    shown <- function() tryCatch(pulse_runs(), error = function(e) NULL)
    session$setInputs(f_mode = "Scenarios", f_yvar = "co2_ppm", f_fair = FALSE,
                      p_bg = "vvM", p_year = 2050L, p_gtc = 100L)
    on$before_open <- shown()
    session$setInputs(f_mode = "Pulse lab")                        # (1) opened at the defaults
    on$opened <- shown(); on$opened_stale <- pulse_stale()
    on$takeaway <- output$f_takeaway
    on$partition <- .app$app_pulse_partition_table(pulse_depth(), pulse_runs()$gtc)
    session$setInputs(p_gtc = 200L)                                # (2) a setting changes
    on$changed <- shown(); on$changed_stale <- pulse_stale()
    on$note <- paste(unlist(output$p_stale_note), collapse = " ")
    session$setInputs(f_yvar = "gmst")                             #     a VIEW toggle is not a setting
    on$view_stale <- pulse_stale()
    session$setInputs(f_yvar = "co2_ppm", p_go = 1L)               # (3) the click
    on$clicked <- shown(); on$clicked_stale <- pulse_stale()
    on$clicked_note <- output$p_stale_note
    session$setInputs(p_gtc = 100L)                                # (4) back to the defaults
    on$back <- shown(); on$back_stale <- pulse_stale()
    session$setInputs(p_gtc = 200L, f_mode = "Scenarios")          #     outside the pulse lab: not grayed
    on$away_stale <- pulse_stale()
  })
  expect_null(on$before_open)
  expect_identical(on$opened, stored)
  expect_false(on$opened_stale)
  expect_identical(on$changed, stored)                 # kept on screen, grayed, not replaced
  expect_true(on$changed_stale)
  expect_match(on$note, substr(.app$APP_PULSE_STALE_NOTE, 1, 30), fixed = TRUE)
  expect_true(on$view_stale)
  expect_null(on$clicked$depth)                        # computed live
  expect_identical(on$clicked$gtc, 200)
  expect_false(on$clicked_stale)
  expect_null(on$clicked_note)
  expect_identical(on$back, stored)
  expect_false(on$back_stale)
  expect_false(on$away_stale)
  # the product off: nothing is drawn until the click, which computes the same thing live
  mock(FALSE, {
    shown <- function() tryCatch(pulse_runs(), error = function(e) NULL)
    session$setInputs(f_mode = "Pulse lab", f_yvar = "co2_ppm", f_fair = FALSE,
                      p_bg = "vvM", p_year = 2050L, p_gtc = 100L)
    off$opened <- shown(); off$opened_stale <- pulse_stale()
    session$setInputs(p_go = 1L)
    off$clicked <- shown(); off$takeaway <- output$f_takeaway
    off$partition <- .app$app_pulse_partition_table(pulse_depth(), pulse_runs()$gtc)
  })
  expect_null(off$opened)
  expect_false(off$opened_stale)
  expect_null(off$clicked$depth)
  expect_identical(off$takeaway, on$takeaway)          # what the reader is told is the same either way
  expect_identical(off$partition, on$partition)
})

#' What the gray-out's three pieces fail to agree on (character(0) if they agree)
apre_grayout_problems <- function(ids, srv, ui) {
  srv_txt <- paste(srv, collapse = "\n"); ui_txt <- paste(ui, collapse = "\n")
  bad <- character(0)
  for (id in ids) {
    if (!grepl(sprintf("output$%s <-", id), srv_txt, fixed = TRUE)) bad <- c(bad, paste("no server output", id))
    if (!grepl(sprintf("Output(\"%s\"", id), ui_txt, fixed = TRUE)) bad <- c(bad, paste("no ui output", id))
  }
  if (!grepl("sendCustomMessage(\"ccx_pulse_stale\"", srv_txt, fixed = TRUE)) bad <- c(bad, "server sends no ccx_pulse_stale")
  if (!grepl("addCustomMessageHandler('ccx_pulse_stale'", ui_txt, fixed = TRUE)) bad <- c(bad, "ui has no handler")
  if (!grepl(".pulse-stale {", ui_txt, fixed = TRUE)) bad <- c(bad, "ui has no .pulse-stale rule")
  if (!grepl("toggle('pulse-stale'", ui_txt, fixed = TRUE)) bad <- c(bad, "the handler does not toggle .pulse-stale")
  bad
}

test_that("11. MUTATION: the gray-out reaches every output that draws the result", {
  srv <- readLines(file.path(.root, "app", "server.R"), warn = FALSE)
  ui  <- readLines(file.path(.root, "app", "ui.R"), warn = FALSE)
  ids <- .app$APP_PULSE_RESULT_IDS
  expect_identical(apre_grayout_problems(ids, srv, ui), character(0))
  # every output that reads the pulse result is grayed with it
  b <- apre_server_body(srv)
  readers <- character(0)
  walk <- function(x) {
    if (is.call(x)) {
      if (identical(x[[1]], as.name("<-")) && is.call(x[[2]]) && identical(x[[2]][[1]], as.name("$")) &&
          identical(x[[2]][[2]], as.name("output")) && "pulse_runs" %in% all.names(x[[3]]))
        readers <<- c(readers, as.character(x[[2]][[3]]))
      for (a in as.list(x)[-1]) if (!missing(a)) walk(a)
    }
  }
  walk(b)
  expect_true(length(readers) >= 4L)
  expect_setequal(readers, ids)
  # mutants: an id that is not an output; a handler that toggles another class
  expect_match(apre_grayout_problems(c(ids, "f_nope"), srv, ui), "no server output f_nope", all = FALSE)
  ui2 <- sub("toggle('pulse-stale'", "toggle('pulse-old'", ui, fixed = TRUE)
  expect_false(identical(ui2, ui))
  expect_match(apre_grayout_problems(ids, srv, ui2), "does not toggle")
})

# 2026-10-20 (h), Marcus: while the pulse lab's result is grayed its charts still hold the PREVIOUS run, so their
# downloads carry the gray-out note instead of that run's data (the CSV's "link to this view" already holds the
# new settings). What a downloaded CSV holds: "data" (rows after the header), "note" or "other".
apre_dl_state <- function(lines) {
  rows <- lines[!startsWith(lines, .app$APP_DL_COMMENT)]
  if (length(rows) > 1) return("data")                 # a column-name line and at least one row
  if (any(grepl(.app$APP_PULSE_STALE_NOTE, lines, fixed = TRUE))) return("note")
  "other"
}

test_that("12. MUTATION: the pulse charts' downloads carry the note while grayed, the run otherwise", {
  skip_if_not_installed("shiny")
  srv_txt <- readLines(file.path(.root, "app", "server.R"))
  run <- function(txt) {
    srv_fn <- function() eval(parse(text = txt), envir = new.env(parent = .app))
    st <- new.env()
    withr::local_options(ccx.app_precompute = TRUE)
    rm(list = ls(.app$APP_PRE_PULSE), envir = .app$APP_PRE_PULSE)
    withCallingHandlers(shiny::testServer(srv_fn(), {
      session$setInputs(f_mode = "Scenarios", f_yvar = "co2_ppm", f_fair = FALSE,
                        p_bg = "vvM", p_year = 2050L, p_gtc = 100L)
      session$setInputs(f_mode = "Pulse lab")
      st$opened <- readLines(output$f_partition_csv)
      session$setInputs(p_gtc = 200L)
      st$grayed <- readLines(output$f_partition_csv)
      st$grayed_png <- file.size(output$f_partition_png)
      session$setInputs(p_go = 1L)
      st$clicked <- readLines(output$f_partition_csv)
    }), warning = function(w)
      if (grepl("No shared levels found", conditionMessage(w), fixed = TRUE)) invokeRestart("muffleWarning"))
    st
  }
  st <- run(srv_txt)
  expect_identical(apre_dl_state(st$opened), "data")
  expect_identical(apre_dl_state(st$grayed), "note")
  expect_gt(st$grayed_png, 0)
  expect_identical(apre_dl_state(st$clicked), "data")
  # MUTATION: server.R without the `withheld =` argument downloads the previous run while grayed
  k <- grep("withheld = function(id)", srv_txt, fixed = TRUE)
  expect_length(k, 1L)
  mut <- srv_txt
  mut[k - 1L] <- sub(",\\s*$", ")", mut[k - 1L]); mut <- mut[-k]
  expect_identical(apre_dl_state(run(mut)$grayed), "data")
})
