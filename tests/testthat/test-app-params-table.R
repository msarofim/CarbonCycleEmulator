# =====================================================================
# Gate: the app's PARAMETER LABEL TABLE covers the parameter set (2026-09-22).
#
# WHAT THIS GUARDS. "Under the hood" prints a table headed "These are the
# numbers the calibration fits", one row per name in CCX_PARAM_NAMES, with a
# plain-English description and a unit. Those two columns cannot be derived
# from CCX_PARAM_TABLE -- it carries transforms, boxes and priors, and no prose
# -- so they are hand-written, and a hand-written table against a moving
# parameter set decouples. It HAD decoupled: the table shipped in the ~22-name
# era still carried retired names (`beta`, `sigma_co2`) and had none of the
# HILDA / pump / seasonal-ML / limb names, so most of the 38 rows printed NA
# under that heading. Marcus caught it in review (2026-09-22, item U1).
#
# The failure is SILENT in the project's usual way: `unname(desc[nm])` on a
# missing name returns NA and renders as an empty cell. Nothing errors, the
# table still has the right number of rows, and the page still looks finished.
#
# ⚠ MUTATION-TESTED. Every assertion is paired with a deliberately broken table
# that it must REJECT. A gate that has only ever passed has not been shown to
# be a gate (project rule, ~/.claude/CLAUDE.md).
#
# The check is STATIC in the sense that matters: params_meta.R defines only a
# literal and two functions, so it loads without the app, its C++ compile or
# its spin-up. CCX_PARAM_NAMES comes from setup.R sourcing R/.
# =====================================================================

.pm_file <- file.path(.root, "app", "R", "params_meta.R")
.pm_env  <- new.env(parent = environment())
if (file.exists(.pm_file)) sys.source(.pm_file, envir = .pm_env)

.pm_have <- file.exists(.pm_file) &&
  exists("APP_PARAM_META", envir = .pm_env, inherits = FALSE)

skip_if_no_param_meta <- function()
  testthat::skip_if_not(.pm_have, "app/R/params_meta.R is not present")

.pm_get <- function(n) get(n, envir = .pm_env, inherits = FALSE)

test_that("the shipped label table covers exactly this build's parameter set", {
  skip_if_no_param_meta()
  v <- .pm_get("app_validate_param_meta")
  problems <- v(CCX_PARAM_NAMES, .pm_get("APP_PARAM_META"),
                .pm_get("APP_PARAM_META_RETIRED"))
  expect_equal(problems, character(0), info = paste(problems, collapse = " | "))
})

test_that("the rendered table has a description and a unit on every row", {
  skip_if_no_param_meta()
  tab <- .pm_get("app_param_table")(CCX_PARAM_NAMES, ccx_default_params(),
                                    .pm_get("APP_PARAM_META"))
  # The NA column is the whole bug: assert on the rendered frame, not only on
  # the validator, because the validator is what the renderer calls and a
  # regression could land in either.
  expect_equal(nrow(tab), length(CCX_PARAM_NAMES))
  expect_true(all(c("Parameter", "Value", "Units") %in% names(tab)))
  expect_false(anyNA(tab$Parameter))
  expect_false(anyNA(tab$Units))
  expect_true(all(nzchar(tab$Parameter)))
  expect_true(all(nzchar(tab$Units)))
})

test_that("a likelihood-only parameter still gets a row, with an em-dash value", {
  skip_if_no_param_meta()
  # rep_dC and the gradient offsets have no slot in ccx_default_params(): they
  # score the model, they cannot move a trajectory. They are still names the
  # calibration fits, so they belong in the table -- with no value rather than
  # no row.
  tab <- .pm_get("app_param_table")(CCX_PARAM_NAMES, ccx_default_params(),
                                    .pm_get("APP_PARAM_META"))
  i <- match("rep_dC", CCX_PARAM_NAMES)
  expect_false(is.na(i))
  expect_identical(tab$Value[i], "—")
  expect_true(nzchar(tab$Parameter[i]))
})

# ---- MUTATION TESTS: each must FAIL the gate ------------------------
test_that("the gate rejects a table that has gone short", {
  skip_if_no_param_meta()
  v <- .pm_get("app_validate_param_meta")
  meta <- .pm_get("APP_PARAM_META")
  broken <- meta[setdiff(names(meta), "kz")]          # the U1 failure exactly
  problems <- v(CCX_PARAM_NAMES, broken, .pm_get("APP_PARAM_META_RETIRED"))
  expect_true(length(problems) > 0)
  expect_true(any(grepl("kz", problems)))
})

test_that("the gate rejects a label for a name the build does not fit", {
  skip_if_no_param_meta()
  v <- .pm_get("app_validate_param_meta")
  meta <- .pm_get("APP_PARAM_META")
  meta$a_name_that_left <- list(desc = "gone", unit = "—")
  problems <- v(CCX_PARAM_NAMES, meta, .pm_get("APP_PARAM_META_RETIRED"))
  expect_true(any(grepl("a_name_that_left", problems)))
})

test_that("the gate rejects an empty description or unit", {
  skip_if_no_param_meta()
  v <- .pm_get("app_validate_param_meta")
  ret <- .pm_get("APP_PARAM_META_RETIRED")
  m1 <- .pm_get("APP_PARAM_META"); m1$q10$desc <- ""
  expect_true(any(grepl("q10", v(CCX_PARAM_NAMES, m1, ret))))
  m2 <- .pm_get("APP_PARAM_META"); m2$q10$unit <- NULL
  expect_true(any(grepl("q10", v(CCX_PARAM_NAMES, m2, ret))))
})

test_that("a retired name must be DECLARED retired, not merely absent", {
  skip_if_no_param_meta()
  v <- .pm_get("app_validate_param_meta")
  meta <- .pm_get("APP_PARAM_META")
  # `beta` is in the table on purpose (a pre-2026-08-14 posterior renders prose
  # instead of NA). Drop it from the declared-retired vector and the gate must
  # notice -- otherwise the retired list is decoration.
  problems <- v(CCX_PARAM_NAMES, meta, character(0))
  expect_true(any(grepl("beta", problems)))
})

test_that("the renderer REPORTS a broken table instead of printing NAs", {
  skip_if_no_param_meta()
  meta <- .pm_get("APP_PARAM_META")
  broken <- meta[setdiff(names(meta), "kz")]
  tab <- .pm_get("app_param_table")(CCX_PARAM_NAMES, ccx_default_params(), broken)
  expect_true("Problem" %in% names(tab))
  expect_false("Parameter" %in% names(tab))
})

# ---- THE "Set" COLUMN (2026-10-06, Marcus: "Mark held rows (Recommended)") ---------------------
# The heading said every row is FITTED while the canonical HOLDS some (hilda33p: ten, npp_tsens and
# six others at 0, unmarked). The column is generated from the mode file's own lists -- never typed --
# and these tests hold it to them. `pt_set_problems()` is the check both the canonical test and its
# mutation use, so the mutation exercises the same code the real assertion runs.
pt_set_problems <- function(tab, rows, fitted, held) {
  p <- character(0)
  if (!"Set" %in% names(tab)) return("no Set column")
  for (n in held)   if (!identical(tab$Set[match(n, rows)], "held"))   p <- c(p, paste("not marked held:", n))
  for (n in fitted) if (!identical(tab$Set[match(n, rows)], "fitted")) p <- c(p, paste("not marked fitted:", n))
  if (sum(tab$Set == "held") != length(held)) p <- c(p, sprintf("%d rows marked held, %d pins", sum(tab$Set == "held"), length(held)))
  p
}

test_that("the Set column follows the lists it is given, and is absent without a mode", {
  skip_if_no_param_meta()
  f <- .pm_get("app_param_table")
  tab0 <- f(CCX_PARAM_NAMES, ccx_default_params(), .pm_get("APP_PARAM_META"))
  expect_false("Set" %in% names(tab0))          # the defaults: nothing was fitted, so no column
  held <- c("kz", "q10"); fitted <- setdiff(CCX_PARAM_NAMES, held)
  tab <- f(CCX_PARAM_NAMES, ccx_default_params(), .pm_get("APP_PARAM_META"), fitted = fitted, held = held)
  expect_equal(pt_set_problems(tab, CCX_PARAM_NAMES, fitted, held), character(0))
  # a row in neither list prints an em-dash, not a guess
  tab2 <- f(CCX_PARAM_NAMES, ccx_default_params(), .pm_get("APP_PARAM_META"), fitted = setdiff(fitted, "h_ml"), held = held)
  expect_identical(tab2$Set[match("h_ml", CCX_PARAM_NAMES)], "—")
})

test_that("at the SHIPPED canonical, the held rows are exactly the mode file's pins", {
  skip_if_no_param_meta()
  md <- readRDS(ccx_mode_file())
  rows <- c(CCX_PARAM_NAMES, setdiff(ccx_gated_names(ccx_mode_struct(md)), CCX_PARAM_NAMES))
  held <- names(ccx_mode_pins(md))
  tab <- .pm_get("app_param_table")(CCX_PARAM_NAMES, ccx_default_params(), .pm_get("APP_PARAM_META"),
                                    extra = ccx_gated_names(ccx_mode_struct(md)),
                                    fitted = md$param_names, held = held)
  expect_equal(pt_set_problems(tab, rows, md$param_names, held), character(0))
  expect_false(any(tab$Set == "—"), info = "every row of the canonical is either fitted or held")
})

# ---- MUTATIONS: each must be REJECTED --------------------------------------------------------------
test_that("MUTATION: a column that says 'fitted' everywhere fails the canonical's check", {
  skip_if_no_param_meta()
  md <- readRDS(ccx_mode_file())
  held <- names(ccx_mode_pins(md)); skip_if(!length(held), "the canonical holds nothing")
  rows <- c(CCX_PARAM_NAMES, setdiff(ccx_gated_names(ccx_mode_struct(md)), CCX_PARAM_NAMES))
  # the failure this column exists to fix: the pins passed as fitted, i.e. not passed at all
  tab <- .pm_get("app_param_table")(CCX_PARAM_NAMES, ccx_default_params(), .pm_get("APP_PARAM_META"),
                                    extra = ccx_gated_names(ccx_mode_struct(md)),
                                    fitted = c(md$param_names, held), held = character(0))
  expect_true(length(pt_set_problems(tab, rows, md$param_names, held)) > 0)
})

test_that("MUTATION: a name both fitted and held, or held with no row, is REPORTED, not rendered", {
  skip_if_no_param_meta()
  f <- .pm_get("app_param_table")
  tab <- f(CCX_PARAM_NAMES, ccx_default_params(), .pm_get("APP_PARAM_META"),
           fitted = CCX_PARAM_NAMES, held = "kz")
  expect_true("Problem" %in% names(tab))
  expect_true(any(grepl("both fitted and held: kz", tab$Problem, fixed = TRUE)))
  tab2 <- f(CCX_PARAM_NAMES, ccx_default_params(), .pm_get("APP_PARAM_META"),
            fitted = CCX_PARAM_NAMES, held = "a_pin_with_no_row")
  expect_true(any(grepl("held but has no row: a_pin_with_no_row", tab2$Problem, fixed = TRUE)))
})
