# =====================================================================
# Gate: the pulse-lab permanence box's PROPORTIONALITY and HORIZON numbers.
#
# ⛔ WHY. Until 2026-09-26 the box said the proportionality was "stated, not
# shown". It is now SHOWN -- but shown by a DIAGNOSTIC, and the app quotes the
# answer from named constants in global.R. That is a label carrying a
# measurement made in another file, which is the caption-sync bug class this
# project keeps hitting: the measurement moves, the sentence does not.
#
# So this re-reads `calibration/diag_pulse_vs_tcre.R`'s own CSV and requires the
# constants to still describe it. ⚠ It does NOT re-run the model (that is ~2 min);
# it checks the CONSTANT against the ARTIFACT. If the CSV is absent the gate
# SKIPS with a reason rather than passing silently -- a gate that cannot run
# must say so ([[broken_gate_reports_nothing]]).
# =====================================================================
.root <- local({
  d <- normalizePath(getwd(), mustWork = FALSE)
  for (i in 1:8) { if (file.exists(file.path(d, "DESIGN.md"))) break; d <- dirname(d) }
  d
})

# the constants, parsed out of global.R (not sourced -- see test-stylised-takeaway.R)
.env <- new.env(parent = globalenv())
.want <- c("APP_PULSE_LIN_SIZES", "APP_PULSE_LIN_SPREAD", "APP_PULSE_LIN_HORIZON", "APP_PULSE_PER1000_ABOUT",
           "APP_PULSE_PER1000_BY_HORIZON", "APP_PULSE_LIN_SRC")
for (e in parse(file.path(.root, "app", "global.R")))
  if (is.call(e) && length(e) >= 3L && identical(as.character(e[[1]]), "<-") &&
      is.name(e[[2]]) && as.character(e[[2]]) %in% .want) eval(e, .env)

test_that("the permanence box's constants are all defined", {
  for (w in .want) expect_false(is.null(get0(w, envir = .env)), info = w)
})

.csv <- local({
  f <- list.files(file.path(.root, "outputs", "diagnostics"),
                  pattern = "^pulse_vs_tcre_[0-9]{8}\\.csv$", full.names = TRUE)
  if (!length(f)) NULL else f[order(basename(f), decreasing = TRUE)][1]
})

test_that("APP_PULSE_LIN_* still describe the driver's own measurement", {
  skip_if(is.null(.csv), "no pulse_vs_tcre CSV built; run calibration/diag_pulse_vs_tcre.R")
  R <- utils::read.csv(.csv)
  h <- .env$APP_PULSE_LIN_HORIZON
  v <- R$per1000[R$horizon == h]
  expect_gt(length(v), 1L)                       # a spread needs >1 size
  # the SIZE RANGE the claim covers must actually be the range measured
  expect_equal(range(R$gtc), as.numeric(.env$APP_PULSE_LIN_SIZES))
  # the quoted spread, to the precision the app prints it at (one decimal)
  got <- 100 * (max(v) - min(v)) / mean(v)
  expect_equal(round(got, 1), .env$APP_PULSE_LIN_SPREAD, tolerance = 0.05,
               info = sprintf("measured spread %.2f %%, constant says %.1f %%",
                              got, .env$APP_PULSE_LIN_SPREAD))
})

test_that("the HORIZON table still matches, and every horizon is 'about' the box's one figure", {
  skip_if(is.null(.csv), "no pulse_vs_tcre CSV built")
  R <- utils::read.csv(.csv)
  tab <- .env$APP_PULSE_PER1000_BY_HORIZON
  ref <- max(R$gtc[R$gtc <= 100])                # the size the box quotes
  for (nm in names(tab)) {
    v <- R$per1000[R$gtc == ref & R$horizon == as.integer(nm)]
    skip_if(!length(v), paste("horizon", nm, "not in the CSV"))
    expect_equal(round(v, 2), unname(tab[[nm]]), tolerance = 0.005,
                 info = sprintf("+%s yr: measured %.3f, constant %.2f", nm, v, tab[[nm]]))
  }
  # ⭐ THE CLAIM IS THE SENTENCE, not just the values. Until 2026-10-01 the box said
  # the figure was "flat in pulse size but NOT in when you look" and this asserted it
  # FELL with horizon (hilda29l: 1.43 / 1.20 / 1.03 / 0.97). At hilda33d it is nearly
  # flat (1.44 / 1.37 / 1.36 / 1.41) and Marcus ruled the box says "about 1.4 dC per
  # 1000 GtC" (review 10-01c A2). So the assertion is now the one that sentence makes:
  # EVERY measured horizon rounds, at one decimal, to APP_PULSE_PER1000_ABOUT -- and so
  # does the box's own live headline at the defaults (100 GtC, +100 yr). If a refit
  # brings the horizon dependence back, this fails and the sentence must change.
  about <- .env$APP_PULSE_PER1000_ABOUT
  v_all <- R$per1000[R$gtc == ref & R$horizon %in% as.integer(names(tab))]
  expect_equal(length(v_all), length(tab))
  expect_true(all(round(v_all, 1) == about),
              info = sprintf("measured %s; the box says about %.1f",
                             paste(sprintf("%.3f", v_all), collapse = " / "), about))
  head100 <- R$per1000[R$gtc == ref & R$horizon == .env$APP_PULSE_LIN_HORIZON]
  expect_equal(round(head100, 1), about,
               info = sprintf("headline at +%d yr %.3f", .env$APP_PULSE_LIN_HORIZON, head100))
})
