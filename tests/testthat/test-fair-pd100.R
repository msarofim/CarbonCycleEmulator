# =====================================================================
# Gate: card 5's FaIR PD100 line (data/fair_pd100.rds) is the file it says it is, on the
# protocol card 5 runs.
#
# RULED (Marcus 2026-10-11): FaIR 2.2.4 (calib 1.6.0) on Joos's PD100, climate free, the
# 841-config mean, mid-release time axis, to 2320. Built by data-raw/build_fair_pd100.R from
# FaIRtoFrEDI/run_fair_pd100_for_ccx.py's export.
#
# ⛔ WHY A TEST, when the build script already refuses a wrong file: the .rds is what the app
# reads, and nothing stops it being rebuilt from a different download, or the download being
# replaced, or JOOS_* moving after the build. Each of those would draw a FaIR line on another
# experiment with no error. So this re-derives the link from the shipped .rds to the download
# (sha256, and the MANIFEST) and from the .rds's provenance to R/joos_irf.R's constants.
# =====================================================================
.dir  <- file.path(.root, "data-raw", "downloads", "fair_v160_pd100")
.stem <- "fair_pd100_100GtC_2015_ref2010_calib160"
.rds  <- file.path(.root, "data", "fair_pd100.rds")
FAIR_PD100_LABEL_WANT <- "FaIR 2.2.4 (calib 1.6.0)"
FAIR_PD100_T_FIRST    <- 0.5     # mid-release: the first timebound after the release year
FAIR_PD100_T_NEED     <- 300     # card 5 reads IRF at 300 yr (app/R/review.R RV_IRF_READ)

test_that("the shipped FaIR PD100 .rds is the MANIFEST's download, byte for byte", {
  skip_if_not(file.exists(.rds), "data/fair_pd100.rds not built (Rscript data-raw/build_fair_pd100.R)")
  d <- readRDS(.rds)
  csv <- file.path(.dir, paste0(.stem, ".csv"))
  # data-raw/downloads/ is gitignored (repo convention): a fresh clone has the .rds, not the
  # export. SKIP with the reason rather than pass -- the other two blocks still run on the .rds.
  skip_if_not(file.exists(csv), paste("FaIR export not present locally:", csv,
                                      "(FaIRtoFrEDI/run_fair_pd100_for_ccx.py writes it)"))
  sha <- digest::digest(file = csv, algo = "sha256")
  expect_identical(attr(d, "source_sha256"), sha)
  man <- utils::read.csv(file.path(.dir, "MANIFEST.csv"), stringsAsFactors = FALSE)
  expect_identical(man$sha256[man$file == paste0(.stem, ".csv")], sha)
  # and the rows ARE that file's rows (a stale .rds with a fresh sha attribute is caught here)
  raw <- utils::read.csv(csv, comment.char = "#")
  expect_identical(d$t, raw$t_yr)
  expect_identical(d$irf_mean, raw$irf_mean)
})

test_that("its protocol is card 5's: JOOS_* constants, label, configs, climate, time axis", {
  skip_if_not(file.exists(.rds), "data/fair_pd100.rds not built")
  p <- attr(readRDS(.rds), "provenance")
  expect_equal(as.numeric(p$ref_year), JOOS_REF_YEAR, tolerance = 0)
  expect_equal(as.numeric(p$pulse_year), JOOS_PULSE_YR, tolerance = 0)
  expect_equal(as.numeric(p$pulse_GtC), JOOS_PULSE, tolerance = 0)
  expect_equal(as.numeric(p$joos_GtC_per_ppm), JOOS_PPM_PER, tolerance = 0)
  expect_identical(p$label, FAIR_PD100_LABEL_WANT)
  expect_identical(as.integer(p$n_configs), 841L)
  expect_true(startsWith(p$climate, "free"))
  expect_true(grepl("mid-release", p$t_axis, fixed = TRUE))
  expect_identical(p$script_uncommitted_changes, "no")
  # the driver's gates ran and passed (it asserts them; this checks the record says so)
  expect_identical(p$gate_G3_zero_pulse, "bit-identical")
  for (g in c("gate_G1_inverse", "gate_G2_control", "gate_G4_first_year"))
    expect_true(grepl("<", p[[g]], fixed = TRUE), info = g)
})

test_that("the curve covers card 5's window and is a pulse decay", {
  skip_if_not(file.exists(.rds), "data/fair_pd100.rds not built")
  d <- readRDS(.rds)
  expect_equal(d$t[1], FAIR_PD100_T_FIRST, tolerance = 0)
  expect_true(max(d$t) >= FAIR_PD100_T_NEED)
  expect_true(all(d$irf_p05 > 0 & d$irf_p95 < 1))
  expect_true(all(diff(d$irf_mean) < 0))                    # free climate still decays
  expect_true(all(d$irf_p05 <= d$irf_median & d$irf_median <= d$irf_p95))
})
