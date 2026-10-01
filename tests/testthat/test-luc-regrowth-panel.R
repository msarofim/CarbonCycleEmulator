# =====================================================================
# Gate: the "Forest regrowth, on its own" panel (REGROWTH TIER 1, 2026-09-24).
#
# The DATA behind this panel is gated in test-luc-gross-split.R. What is left,
# and what this file guards, is the three ways the PANEL can be silently wrong
# while the product is right:
#
#   1. AN OUTPUT RENDERED BUT NEVER PLACED (or placed but never rendered). The
#      app's own silent-gate family: `ui.R` and `server.R` are two files naming
#      the same strings, and a mismatch renders nothing with no error anywhere.
#      Checked both directions.
#   2. `luc_scale` NOT APPLIED, OR APPLIED TO ONE HALF. The product is stored
#      UNSCALED because `luc_scale` is a FITTED name; `global.R` multiplies. If
#      it stopped, the panel's readouts would disagree with the series the model
#      actually burns by ~18 %, in the same direction on all three numbers, so
#      nothing on screen would look wrong.
#   3. THE "ASSERTED" SENTENCE DISAPPEARING. The panel's whole honesty claim is
#      that the split is imported from GCB's bookkeeping models and NOT measured
#      here (CHANGELOG 2026-09-24 h showed this record cannot see it). Copy is
#      editable and this sentence is load-bearing, so its absence is a failure.
#
# ⚠ STATIC, like test-review-cards.R: evaluating ui.R needs global.R, which
# compiles the C++ core and runs a spin-up. A gate nobody can afford to run gets
# skipped.
# ⚠ MUTATION-TESTED: see the "a broken ..." expectations inside each test, which
# apply the defect to a COPY of the source text and require the same check to
# reject it.
# =====================================================================

.lrp_app    <- file.path(.root, "app")
.lrp_ui     <- readLines(file.path(.lrp_app, "ui.R"), warn = FALSE)
.lrp_server <- readLines(file.path(.lrp_app, "server.R"), warn = FALSE)
.lrp_global <- readLines(file.path(.lrp_app, "global.R"), warn = FALSE)
.lrp_plots  <- readLines(file.path(.lrp_app, "R", "plots.R"), warn = FALSE)

# the ONE id the section hangs off; every other output is assembled inside it
LRP_UI_OUTPUT  <- "w_regrowth_ui"
LRP_RENDERED   <- c("w_regrowth_ui", "w_regrowth_plot",
                    "w_regrowth_takeaway", "w_regrowth_caveat")
LRP_PLOT_FN    <- "plot_luc_gross_split"
LRP_ASSERT_RX  <- "ASSERTED"
LRP_SCALE_RX   <- "APP_LUC_SCALE"
# the attribution retired 2026-09-24 (p): the land-use caveat used to credit the
# natural sink's growth to "CO2 fertilisation AND forest regrowth", which names a
# mechanism this model does not contain -- regrowth is netted inside the LUC
# INPUT, and fertilisation was then the only long-term land-uptake term (not
# since hilda33d, 2026-10-01, which adds N-deposition retention).
LRP_RETIRED_RX <- "fertilisation and forest regrowth"
LRP_HEADINGS   <- c("APP_REGROWTH_HEADING", "APP_IMBALANCE_HEADING")

has <- function(txt, rx) any(grepl(rx, txt, fixed = TRUE))

test_that("1a. the section is placed in ui.R and rendered in server.R", {
  expect_true(has(.lrp_ui, sprintf('uiOutput("%s")', LRP_UI_OUTPUT)))
  for (id in LRP_RENDERED)
    expect_true(has(.lrp_server, sprintf("output$%s", id)))
})

test_that("1b. every output the server renders is reachable from the UI", {
  # w_regrowth_ui is placed in ui.R; the other three are assembled INSIDE it,
  # so each must appear in the server's own renderUI body. A renderer whose id
  # appears nowhere else is an orphan that will never draw.
  body <- paste(.lrp_server, collapse = "\n")
  for (id in setdiff(LRP_RENDERED, LRP_UI_OUTPUT))
    expect_gt(length(gregexpr(id, body, fixed = TRUE)[[1]]), 1)
  # MUTATION: an orphaned renderer is a single mention and must be caught
  broken <- gsub('textOutput("w_regrowth_caveat", inline = TRUE)', '""', body, fixed = TRUE)
  expect_equal(length(gregexpr("w_regrowth_caveat", broken, fixed = TRUE)[[1]]), 1)
})

test_that("2. global.R scales BOTH halves and the net by luc_scale", {
  # the loop must cover all three columns; a product column left unscaled is
  # the silent 18 % error
  i <- grep("APP_LUC_SPLIT <- local", .lrp_global)
  expect_length(i, 1)
  blk <- paste(.lrp_global[i:(i + 20)], collapse = "\n")
  for (col in c("gross_GtC", "regrowth_GtC", "net_GtC"))
    expect_true(grepl(col, blk, fixed = TRUE))
  expect_true(grepl(LRP_SCALE_RX, blk, fixed = TRUE))
  # MUTATION: drop one column from the loop and the check must reject it
  broken <- gsub('"regrowth_GtC", ', "", blk, fixed = TRUE)
  expect_false(grepl("regrowth_GtC", broken, fixed = TRUE))
})

test_that("3. the panel says the split is ASSERTED, not measured", {
  # in the plot's own caption (which a screenshot carries) AND in the page copy
  expect_true(has(.lrp_plots, LRP_ASSERT_RX))
  expect_true(has(.lrp_global, LRP_ASSERT_RX))
  # and the server's info box must say the model cannot check it
  body <- paste(.lrp_server, collapse = " ")
  expect_true(grepl("cannot check the split", body, fixed = TRUE))
})

test_that("4. the plot function exists and names its three series", {
  expect_true(has(.lrp_plots, sprintf("%s <- function", LRP_PLOT_FN)))
  for (lab in c("KEY_LUC_GROSS", "KEY_LUC_REGROW", "KEY_LUC_NET"))
    expect_true(has(.lrp_plots, sprintf("%s  ", lab)) || has(.lrp_plots, sprintf("%s ", lab)))
  # the colours are NAMED palette entries, not literals in the plot body
  expect_true(has(.lrp_plots, 'PAL[["luc_gross"]]'))
  expect_true(has(.lrp_plots, 'PAL[["luc_regrow"]]'))
})

test_that("5. the observed window is READ from the product, never typed", {
  # the caption claims "Observed 1959-2024"; if that year were typed in global.R
  # a GCB update would move the data and leave the caption behind -- the
  # caption-sync bug class.
  blk <- paste(.lrp_global, collapse = "\n")
  expect_true(grepl("APP_LUC_SPLIT$obs_window", blk, fixed = TRUE))
  expect_false(grepl('"1959', blk, fixed = TRUE))
  expect_true(grepl("split$obs_window", paste(.lrp_plots, collapse = "\n"), fixed = TRUE))
})

test_that("6. the land-use caveat no longer puts regrowth inside the natural sink", {
  # \u26d4 A REGRESSION GUARD ON A CORRECTED FACT, not on a turn of phrase. The
  # page drew regrowth on this tab from 09-24 (n); a caveat two charts above it
  # saying the sink grew "through CO\u2082 fertilisation and forest regrowth" makes
  # the page contradict itself, and nothing else in the suite would see it.
  body <- paste(.lrp_server, collapse = " ")
  expect_false(grepl(LRP_RETIRED_RX, body, fixed = TRUE))
  # and the replacement must still say where regrowth IS counted
  expect_true(grepl("counted inside the", body, fixed = TRUE))
  # MUTATION: put the retired attribution back and the same check must reject it
  broken <- paste(body, LRP_RETIRED_RX)
  expect_true(grepl(LRP_RETIRED_RX, broken, fixed = TRUE))
})

test_that("7. cross-referenced headings come from ONE shared constant", {
  # \u26a0 ui.R renders the heading, server.R quotes it by name in prose. Two
  # files, one string: if either retypes it, renaming a heading leaves the prose
  # pointing at a section that no longer exists, and the page still renders.
  glb  <- paste(.lrp_global, collapse = "\n")
  ui   <- paste(.lrp_ui, collapse = "\n")
  body <- paste(.lrp_server, collapse = "\n")
  for (nm in LRP_HEADINGS) {
    expect_true(grepl(paste0(nm, " "), glb) || grepl(paste0(nm, "  "), glb))
    expect_true(grepl(sprintf("h5(%s)", nm), ui, fixed = TRUE))
    expect_true(grepl(nm, body, fixed = TRUE))
  }
  # the literals must NOT be retyped in ui.R or server.R
  expect_false(grepl('h5("Forest regrowth, on its own")', ui, fixed = TRUE))
  expect_false(grepl("h5(\"Is the model's land sink too high?\")", ui, fixed = TRUE))
})
