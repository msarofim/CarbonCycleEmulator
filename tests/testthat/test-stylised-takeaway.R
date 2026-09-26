# =====================================================================
# The "Build your own" takeaway's second clause.
#
# ⛔⛔ WHY THIS FILE EXISTS. The clause shipped a statement that was FALSE ON
# THE APP'S OWN DEFAULT -- "a fixed rate only ever approaches zero", printed for
# a `rate` pathway whose slider defaults to +1 %/yr and therefore GROWS. It was
# unreachable by any test because it lived inside a `renderText`. The lesson is
# the app's own: a sentence that asserts something about the run is a CLAIM, and
# a claim needs a gate. `app_stylised_tail_clause()` exists to be gated here.
#
# ⚠ These assert the DIRECTION the sentence claims, never its exact prose --
# Marcus owns the wording, and a test that pins wording would fail on every
# edit he makes. Each check is a statement about the PATHWAY.
# =====================================================================
.root <- local({
  d <- normalizePath(getwd(), mustWork = FALSE)
  for (i in 1:8) { if (file.exists(file.path(d, "DESIGN.md"))) break; d <- dirname(d) }
  d
})

# ⭐ THE TWO FUNCTIONS ARE PARSED OUT OF global.R, NOT SOURCED WITH IT. Sourcing
# global.R loads the whole app -- every rds product, the constraint map, the
# parameter tables -- which took over two minutes for this one file. Parsing and
# evaluating only the two assignments we need takes milliseconds, and it also
# makes the test independent of the DATA vintage: the pathway arithmetic is what
# is under test, not this year's emissions history.
.env <- new.env(parent = globalenv())
.want <- c("app_stylised_emissions", "app_stylised_tail_clause")
for (e in parse(file.path(.root, "app", "global.R"))) {
  if (is.call(e) && length(e) >= 3L && identical(as.character(e[[1]]), "<-") &&
      is.name(e[[2]]) && as.character(e[[2]]) %in% .want) eval(e, .env)
}
test_that("both functions were found in global.R", {
  # ⚠ If a rename orphaned either name, every test below would silently test
  # NOTHING -- the loop above would simply never fire. Asserted, not assumed.
  for (w in .want) expect_true(is.function(get0(w, envir = .env)), info = w)
})

# STUBBED inputs. Small, explicit and independent of the real data products: the
# claim under test is what the clause says about a pathway, and a stub makes the
# pathway exactly known. e0 = 10 GtC/yr makes every ratio readable by eye.
YRS <- c(1850L, 2150L)
E0  <- 10
.env$APP_EMIS_HIST <- data.frame(year = 1850:2024,
                                 fossil_GtC = c(rep(1, 174), E0))
.env$APP_SSP_EMIS  <- data.frame(scenario = "ssp245", year = c(1850L, 2150L),
                                 fossil_GtC = c(0, 5), luc_GtC = c(1, 1))
clause <- function(kind, rate_pct = 0, to_zero_year = 2060) {
  em <- .env$app_stylised_emissions(kind, YRS, to_zero_year = to_zero_year,
                                    rate_pct = rate_pct, background = "ssp245")
  .env$app_stylised_tail_clause(kind, rate_pct, em, E0)
}
# the words that only make sense for a pathway that DOES approach zero
APPROACH <- "approach"
STOPS    <- "emissions stop"

test_that("the DEFAULT rate pathway does not claim emissions approach zero", {
  # ⭐ THE REGRESSION. s_rate's slider default is +1: growth, not decay.
  cl <- clause("rate", rate_pct = 1)
  expect_false(grepl(APPROACH, cl, fixed = TRUE))
  expect_false(grepl(STOPS, cl, fixed = TRUE))
  expect_true(grepl("grow", cl, fixed = TRUE))
})

test_that("a NEGATIVE rate says it approaches zero without reaching it", {
  cl <- clause("rate", rate_pct = -5)
  expect_true(grepl("never reach zero", cl, fixed = TRUE))
  expect_true(grepl(APPROACH, cl, fixed = TRUE))
})

test_that("rate = 0 is described as the CONSTANT pathway, not a third thing", {
  # e0 * (1 + 0)^n IS the constant pathway; describing it twice invites the two
  # descriptions to drift apart.
  expect_identical(clause("rate", rate_pct = 0), clause("constant"))
})

test_that("the CONSTANT pathway never says emissions stop or approach zero", {
  cl <- clause("constant")
  expect_true(grepl("never stop", cl, fixed = TRUE))
  expect_false(grepl(APPROACH, cl, fixed = TRUE))
  expect_false(grepl(STOPS, cl, fixed = TRUE))
})

test_that("only the to_zero pathway says emissions stop", {
  expect_true(grepl(STOPS, clause("to_zero"), fixed = TRUE))
})

test_that("EVERY branch scopes its claim to FOSSIL emissions", {
  # ⭐ 2026-09-26. The scope, not the wording: on every pathway the user's
  # control is fossil-only -- `app_stylised_emissions()` always takes land use
  # from the background scenario -- so no branch may claim something about
  # "emissions" full stop. `to_zero` said "even when emissions stop", which
  # overstated what the run did, because the pathway's TOTAL CO2 emissions never
  # reach zero. This asserts the qualifier survives future edits to the prose.
  for (k in list(c("to_zero", 0), c("constant", 0), c("rate", 2), c("rate", -2))) {
    cl <- clause(k[[1]], rate_pct = as.numeric(k[[2]]))
    expect_match(cl, "fossil emissions", ignore.case = TRUE,
                 info = paste("branch", k[[1]], k[[2]], "does not scope to fossil"))
  }
})

test_that("every claimed number is the one the PATHWAY actually has", {
  # A computed sentence is only better than an asserted one if the numbers in it
  # come from the object it describes.
  for (r in c(-5, -0.5, 0.5, 5)) {
    em <- .env$app_stylised_emissions("rate", YRS, rate_pct = r, background = "ssp245")
    y_end <- max(em$year)
    e_end <- em$fossil_GtC[em$year == y_end]
    cl <- .env$app_stylised_tail_clause("rate", r, em, E0)
    expect_true(grepl(sprintf("%+.1f %%", r), cl, fixed = TRUE),
                info = sprintf("rate %+.1f not quoted", r))
    expect_true(grepl(as.character(y_end), cl, fixed = TRUE))
    # the end-of-run rate, at whichever precision that branch prints
    expect_true(grepl(sprintf("%.1f", e_end), cl, fixed = TRUE) ||
                grepl(sprintf("%.2f", e_end), cl, fixed = TRUE),
                info = sprintf("end rate %.3f not quoted for %+.1f", e_end, r))
  }
})

test_that("the sign of the rate decides the branch, at every slider step", {
  # The defect was a SIGN error, so sweep the slider's own domain (-5..5 by 0.5)
  # rather than test two hand-picked values.
  for (r in seq(-5, 5, by = 0.5)) {
    cl <- clause("rate", rate_pct = r)
    if (r > 0)       expect_true(grepl("grow", cl, fixed = TRUE), info = paste("r =", r))
    else if (r < 0)  expect_true(grepl("fall", cl, fixed = TRUE), info = paste("r =", r))
    else             expect_true(grepl("hold at", cl, fixed = TRUE), info = paste("r =", r))
  }
})
