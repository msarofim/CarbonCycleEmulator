# =====================================================================
# build_fair_pd100.R -- FaIR 2.2.4 (calib 1.6.0) on Joos et al. 2013's PD100, for card 5
#
# RULED (Marcus 2026-10-11, "Run FaIR on Joos's PD100 (Recommended)"): 100 GtC in 2015 on a
# constant-2010 background, climate free as in Joos, the 841-config mean, imported with
# provenance and labelled FaIR 2.2.4 (calib 1.6.0). Same day: the run ends in 2320 (a PD100
# exception to the 2300 end year -- nothing after 2010 reads scenario data); the IRF's time
# axis is mid-release, t = timebound - 2015.5 (FaIR releases the pulse uniformly over 2015).
#
# SOURCE: data-raw/downloads/fair_v160_pd100/, written by
#   FaIRtoFrEDI/run_fair_pd100_for_ccx.py (heat-ed-morbidity, 964aa12)
# with its MANIFEST (sha256) and _provenance.csv. Its four gates and three sanity arms are
# in the provenance and in run_fair_pd100_for_ccx.log beside it.
#
# THIS SCRIPT REFUSES a file whose PROTOCOL is not card 5's: the reference year, pulse year,
# pulse size and GtC-per-ppm normalisation in the provenance must equal R/joos_irf.R's
# JOOS_* constants, which CarboTope's own PD100 uses. A FaIR line run on another protocol
# would plot without complaint and compare two different experiments.
#
# OUTPUT: data/fair_pd100.rds -- t, irf_mean, irf_median, irf_p05, irf_p95, d_gmst_mean,
#   co2_bkg_mean, gmst_bkg_mean; attributes `provenance` (named list) and `source_sha256`.
#
# Usage: Rscript data-raw/build_fair_pd100.R
# =====================================================================
for (f in list.files("R", pattern = "\\.R$", full.names = TRUE)) source(f)

FAIR_PD100_DIR   <- ccx_path("data-raw", "downloads", "fair_v160_pd100")
FAIR_PD100_STEM  <- "fair_pd100_100GtC_2015_ref2010_calib160"
FAIR_PD100_LABEL <- "FaIR 2.2.4 (calib 1.6.0)"
FAIR_PD100_N     <- 841L
FAIR_PD100_OUT   <- ccx_path("data", "fair_pd100.rds")
FAIR_PD100_REPORT_T <- c(20, 100, 300)   # printed only; the horizons card 5 reads (app RV_IRF_READ)

sha256 <- function(p) digest::digest(file = p, algo = "sha256")
cat("\n=== build_fair_pd100.R ===\n")

man <- utils::read.csv(file.path(FAIR_PD100_DIR, "MANIFEST.csv"), stringsAsFactors = FALSE)
for (fn in paste0(FAIR_PD100_STEM, c(".csv", "_provenance.csv"))) {
  row <- man[man$file == fn, ]
  if (nrow(row) != 1L) stop(fn, " is not in MANIFEST.csv exactly once")
  if (!identical(sha256(file.path(FAIR_PD100_DIR, fn)), row$sha256))
    stop(fn, " does not match its MANIFEST sha256")
}
csv <- file.path(FAIR_PD100_DIR, paste0(FAIR_PD100_STEM, ".csv"))
pv <- utils::read.csv(file.path(FAIR_PD100_DIR, paste0(FAIR_PD100_STEM, "_provenance.csv")),
                      stringsAsFactors = FALSE)
prov <- stats::setNames(as.list(pv$value), pv$key)

# ---- the protocol must be card 5's ------------------------------------------
want <- list(ref_year = JOOS_REF_YEAR, pulse_year = JOOS_PULSE_YR, pulse_GtC = JOOS_PULSE,
             joos_GtC_per_ppm = JOOS_PPM_PER)
for (k in names(want)) {
  got <- suppressWarnings(as.numeric(prov[[k]]))
  if (!isTRUE(all.equal(got, as.numeric(want[[k]]), tolerance = 0)))
    stop(sprintf("FaIR PD100 provenance %s = %s, but card 5's protocol has %s", k, prov[[k]], want[[k]]))
}
if (!identical(prov$label, FAIR_PD100_LABEL)) stop("label is '", prov$label, "', not '", FAIR_PD100_LABEL, "'")
if (!identical(as.integer(prov$n_configs), FAIR_PD100_N)) stop("n_configs is ", prov$n_configs)
if (!startsWith(prov$climate, "free")) stop("climate is '", prov$climate, "'; the ruled line is climate free")
if (!grepl("mid-release", prov$t_axis, fixed = TRUE)) stop("t axis is '", prov$t_axis, "'")
if (!identical(prov$script_uncommitted_changes, "no")) stop("the driver had uncommitted changes at run time")

d <- utils::read.csv(csv, comment.char = "#")
need <- c("t_yr", "irf_mean", "irf_median", "irf_p05", "irf_p95", "d_gmst_mean", "co2_bkg_mean", "gmst_bkg_mean")
miss <- setdiff(need, names(d)); if (length(miss)) stop("missing columns: ", paste(miss, collapse = ", "))
names(d)[names(d) == "t_yr"] <- "t"
d <- d[, c("t", setdiff(need, "t_yr"))]
if (any(diff(d$t) <= 0) || any(!is.finite(as.matrix(d)))) stop("t not increasing, or non-finite values")

attr(d, "provenance") <- prov
attr(d, "source_sha256") <- sha256(csv)
saveRDS(d, FAIR_PD100_OUT)
cat(sprintf("[1] %s: %d rows, t %.1f-%.1f yr; %s, %s configs, commit %s\n",
            basename(FAIR_PD100_OUT), nrow(d), min(d$t), max(d$t), prov$label, prov$n_configs,
            substr(prov$git_commit, 1, 7)))
at <- function(h) d$irf_mean[which.min(abs(d$t - h))]
cat(sprintf("    IRF mean at %s yr: %s (Joos fit %s)\n", paste(FAIR_PD100_REPORT_T, collapse = "/"),
            paste(sprintf("%.3f", vapply(FAIR_PD100_REPORT_T, at, 0)), collapse = "/"),
            paste(sprintf("%.3f", joos_irf(FAIR_PD100_REPORT_T)), collapse = "/")))
