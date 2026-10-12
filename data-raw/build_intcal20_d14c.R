# =====================================================================
# build_intcal20_d14c.R -- the pre-bomb D14C target, from the PUBLISHED
# IntCal20 file, carrying the D14C SIGMA IN PERMIL.
#
# WHY (CHANGELOG 2026-10-12 u; citation rulings ledger §C). data/obs_d14c_intcal20.rds
# was built by build_calibration_data.R [4b] through the `rintcal` package, whose
# third column is the 14C-AGE sigma in YEARS (9-11). The likelihood scored the
# d14c_intcal row with it as if it were permil: the published D14C sigma is
# column 5 of intcal20.14c, 1.2-1.4 permil (the corrected row's chi2/n is 0.997
# at the mode, against 0.155). Ruled into the refit: "use the published D14C sigma
# (column 5)" -- and it enters the objective ONLY under label
# hilda_csl3v0kaidgbemwtc (ruled 2026-10-12, "New label (a) (Recommended)"),
# through the structure field `intcal_sd_published`.
#
# WHAT THIS WRITES. data/obs_d14c_intcal20_v2.rds: the shipped table's columns
# year / d14c / err, REPRODUCED from the published file (a gate below), plus
# `sd_d14c` = column 5. The legacy objective keeps reading `err` and is unchanged
# by construction; the shipped data/obs_d14c_intcal20.rds is left as the record.
# `rintcal` is no longer needed: this file is the only input.
#
# THE CONVERSION is build_calibration_data.R [4b]'s, unchanged:
#   F14C = exp(-C14age / 8033)                8033 = Libby mean life (AGE convention)
#   D14C = 1000 (F14C exp(calBP / 8267) - 1)  8267 = 5730-yr mean life (Stuiver-Polach)
# NEITHER is the model's decay constant (the true 5700-yr half-life). IntCal's own
# column 4 is printed beside it as a cross-check (the 10-12 u measurement: within
# 0.106 permil over the scored window).
#
# SOURCE. Reimer et al. (2020), Radiocarbon 62:725-757, doi:10.1017/RDC.2020.41;
# https://intcal.org/curves/intcal20.14c, MANIFEST.csv key `intcal20` (sha256 checked).
# =====================================================================

for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)

IC_FILE    <- ccx_path("data-raw", "downloads", "intcal20", "intcal20.14c")
IC_SHA256  <- "974a66649f2ac8a53e6c99e256b019ac6982f999b12dcf7193162d4c1c09168e"  # MANIFEST.csv `intcal20`
IC_LEGACY  <- ccx_path("data", "obs_d14c_intcal20.rds")
IC_OUT     <- ccx_path("data", "obs_d14c_intcal20_v2.rds")
IC_YEARS   <- c(1700, 1950)       # CE, build_calibration_data.R [4b]'s window
IC_LIBBY   <- 8033                # yr, Libby mean life (the age convention)
IC_SP      <- 8267                # yr, 5730-yr mean life (the Stuiver-Polach D14C convention)
IC_GATE_D14C <- 1e-9              # permil; the legacy d14c must reproduce to roundoff

sha <- unname(tools::sha256sum(IC_FILE))
if (!identical(sha, IC_SHA256)) stop("intcal20.14c sha256 ", sha, " != MANIFEST's ", IC_SHA256)
raw <- utils::read.csv(IC_FILE, comment.char = "#", header = FALSE,
                       col.names = c("calBP", "C14BP", "err", "d14c_pub", "sd_d14c"))
stopifnot(ncol(raw) == 5L, all(is.finite(as.matrix(raw))))
raw$year     <- 1950 - raw$calBP
raw$F14C     <- exp(-raw$C14BP / IC_LIBBY)
raw$d14c     <- 1000 * (raw$F14C * exp(raw$calBP / IC_SP) - 1)
ic <- raw[raw$year >= IC_YEARS[1] & raw$year <= IC_YEARS[2], ]
ic <- ic[order(-ic$year), ]                    # the shipped table runs 1950 -> 1700

# GATE: the legacy columns reproduce the shipped (rintcal-built) table.
leg <- as.data.frame(readRDS(IC_LEGACY))
stopifnot(identical(as.numeric(leg$year), as.numeric(ic$year)))
g_d14c <- max(abs(leg$d14c - ic$d14c))
g_err  <- max(abs(leg$err - ic$err))
cat(sprintf("%d rows %d-%d; legacy reproduction: max |d14c| diff %.2e permil, max |err| diff %g yr\n",
            nrow(ic), min(ic$year), max(ic$year), g_d14c, g_err))
if (g_d14c > IC_GATE_D14C || g_err != 0)
  stop("the published file does not reproduce the shipped rintcal table -- not written")
sc <- ic$year >= 1750 & ic$year < 1941       # the window the row scores at the canonical (Hua from 1941)
cat(sprintf("scored window 1750-1940: sd_d14c %.2f-%.2f permil (mean %.2f) vs the coded err %g-%g;\n",
            min(ic$sd_d14c[sc]), max(ic$sd_d14c[sc]), mean(ic$sd_d14c[sc]), min(ic$err[sc]), max(ic$err[sc])))
cat(sprintf("  IntCal's own column 4 vs this conversion: max |diff| %.3f permil\n",
            max(abs(ic$d14c_pub[sc] - ic$d14c[sc]))))

out <- data.frame(year = ic$year, d14c = ic$d14c, err = ic$err, sd_d14c = ic$sd_d14c)
attr(out, "provenance") <- list(
  source = "Reimer et al. (2020) Radiocarbon 62:725-757, doi:10.1017/RDC.2020.41; https://intcal.org/curves/intcal20.14c",
  file_sha256 = sha, manifest_key = "intcal20",
  columns = c(year = "CE = 1950 - cal BP", d14c = "this file's conversion of column 2 (8033 / 8267)",
              err = "column 3, the 14C-AGE sigma in YEARS (legacy; NOT a D14C sigma)",
              sd_d14c = "column 5, the D14C sigma in permil"),
  ruling = "CHANGELOG 2026-10-12 u; citation rulings ledger section C; label hilda_csl3v0kaidgbemwtc",
  script = "data-raw/build_intcal20_d14c.R", built = format(Sys.Date()))
saveRDS(out, IC_OUT)
cat(sprintf("written: %s\n", IC_OUT))
