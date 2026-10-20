# =====================================================================
# Gate: the app's PRECOMPUTED start-up runs and pulse-lab default (2026-10-20; CHANGELOG 2026-10-20 b).
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
# purpose and requires the check to notice. Test 10 runs the real server (shiny::testServer).
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
  sentinel <- list(runs = list(base = "stored"), depth = "stored depth")
  calls <- 0L
  e <- new.env(parent = .app)    # app_pulse_lab() rebound here, so the mocks below shadow the app's
  lab <- .app$app_pulse_lab; environment(lab) <- e
  e$app_pulse_runs <- function(inp) { calls <<- calls + 1L; "live" }
  e$app_pulse_precomputed <- function() sentinel
  expect_identical(lab(.defaults), list(base = "stored", depth = "stored depth"))
  expect_identical(calls, 0L)
  for (n in names(APRE_PERTURB)) {
    inp <- .defaults; inp[[n]] <- APRE_PERTURB[[n]]
    expect_identical(lab(inp), "live", info = n)
  }
  expect_identical(calls, length(APRE_PERTURB))
  e$app_pulse_precomputed <- function() NULL        # absent, refused or switched off
  expect_identical(lab(.defaults), "live")
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
# server.R's handler for the pulse lab's eventReactive
apre_pulse_handler <- function(lines) {
  ex <- parse(text = lines)
  fn <- eval(ex[[length(ex)]])          # server.R's last value is the server function (test-review-cards.R)
  found <- NULL
  walk <- function(x) {
    if (is.call(x)) {
      if (identical(x[[1]], as.name("<-")) && identical(x[[2]], as.name("pulse_runs")))
        found <<- as.list(x[[3]])
      for (a in as.list(x)[-1]) if (!missing(a)) walk(a)
    }
  }
  walk(body(fn))
  if (is.null(found)) stop("no `pulse_runs <- ...` in server.R")
  found
}

test_that("8. MUTATION: the pulse computation reads only inputs the check covers (static)", {
  expect_setequal(apre_names_read(body(.app$app_pulse_runs), "inp"), names(.defaults))
  srv <- readLines(file.path(.root, "app", "server.R"), warn = FALSE)
  h <- apre_pulse_handler(srv)
  expect_identical(h[[1]], as.name("eventReactive"))
  expect_identical(apre_names_read(h[[2]], "input"), "p_go")            # the trigger
  expect_identical(apre_names_read(as.call(c(as.name("{"), h[-(1:2)])), "input"), character(0))
  expect_true("app_pulse_inputs" %in% all.names(as.call(c(as.name("{"), h[-(1:2)]))))
  # mutant 1: the computation reads a control the defaults do not name
  b <- body(.app$app_pulse_runs); b <- as.call(c(as.list(b), quote(inp$p_dur)))
  expect_false(setequal(apre_names_read(b, "inp"), names(.defaults)))
  # mutant 2: the handler hands the computation an input of its own
  srv2 <- sub("app_pulse_lab(app_pulse_inputs(input))",
              "app_pulse_lab(c(app_pulse_inputs(input), list(p_dur = input$p_dur)))", srv, fixed = TRUE)
  expect_false(identical(srv2, srv))
  expect_identical(apre_names_read(as.call(c(as.name("{"), apre_pulse_handler(srv2)[-(1:2)])), "input"), "p_dur")
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

test_that("10. the real server serves the stored default, computes anything else, and says the same either way", {
  skip_if_not_installed("shiny")
  srv_fn <- function() source(file.path(.root, "app", "server.R"), local = new.env(parent = .app))$value
  press <- function(on, gtc) {
    withr::local_options(ccx.app_precompute = on)
    rm(list = ls(.app$APP_PRE_PULSE), envir = .app$APP_PRE_PULSE)
    res <- NULL
    # ⚠ The mock session renders EVERY output, hidden tabs included, with their inputs unset. One of
    # them, the What-if tab's `c_growth`, then raises ggplot's "No shared levels found" (attributed
    # 2026-10-20 from the call stack). The pulse lab's own plots build without it (checked with FaIR on
    # and off), and the real app's log has none. Only that message is muffled.
    withCallingHandlers(shiny::testServer(srv_fn(), {
      session$setInputs(f_mode = "Pulse lab", f_yvar = "co2_ppm", f_fair = FALSE,
                        p_bg = "vvM", p_year = 2050L, p_gtc = gtc, p_go = 1L)
      res <<- list(pr = pulse_runs(), takeaway = output$f_takeaway,
                   partition = .app$app_pulse_partition_table(pulse_depth(), pulse_runs()$gtc))
    }), warning = function(w) if (grepl("No shared levels found", conditionMessage(w), fixed = TRUE))
      invokeRestart("muffleWarning"))
    res
  }
  served <- press(TRUE, 100L)
  expect_identical(served$pr, c(.pre$pulse$values$runs, list(depth = .pre$pulse$values$depth)))
  live <- press(FALSE, 100L)
  expect_null(live$pr$depth)
  expect_identical(served$takeaway, live$takeaway)
  expect_identical(served$partition, live$partition)
  other <- press(TRUE, 200L)                       # off the default: computed live with the product on
  expect_null(other$pr$depth)
  expect_identical(other$pr$gtc, 200)
  expect_false(identical(other$takeaway, served$takeaway))
})
