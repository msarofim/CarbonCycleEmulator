# =====================================================================
# build_enso_relsst.R -- the RELATIVE-SST ENSO index, low-passed (2026-09-29).
#
# WHY. The audit (CHANGELOG 2026-09-29 d, item 3) found the shipped Nino 3.4
# index demeaned but NOT detrended: +0.0082 degC/yr over 1948-2024, which
# gamma_enso_land turns into a land source rising -0.26 -> +0.31 GtC/yr and
# which vanishes in every projection. Marcus (2026-09-29) ruled: build BOTH
# detrend routes as switch values of ccx_build_forcing(enso_index =), price
# each, then pick one for Torch. `detrend` (a linear fit) needs no data;
# THIS is the other one, the OBSERVATIONAL detrend:
#
#   index = Nino 3.4 anomaly  -  21-yr centered low-pass of the 20S-20N mean anomaly
#
# both from the SAME product (ERSST v6 grid) on the SAME fixed base
# (EIX_CLIM_BASE 1991-2020). The tropical mean IS the forced warming, measured
# rather than fitted ([[threshold_from_obs_or_law]]); low-passing it keeps the
# 2-7 yr ENSO band out of what is subtracted (lib_enso_index.R eix_relative_sst:
# sd 0.877 -> 0.866, 1 % lost, vs 19 % for the unfiltered subtraction).
#
# PRODUCT: ERSST v6, because the SHIPPED index (PSL nina34.data) is v6-based
# (MANIFEST "nino34"; lib_enso_index.R header: v5 and PSL-v6 differ by 15 % in
# amplitude). The v6 grid's own Nino 3.4 is compared against nina34.data below
# as a receipt, since this index REPLACES that product's Nino 3.4 by the grid's.
#
# ⚠ END EFFECT. The centered 21-yr mean is a partial window in the last 10 yr
# of the grid (and the first 10, which are outside the ENSO-active span and
# unused). `partial` in the output flags those months.
#
# Output: data/forcing_enso_relsst.rds -- data.frame(year, month, nino34_grid,
# trop_lp, nino34_relsst_lp, partial) with a `provenance` attribute.
# Usage: Rscript data-raw/build_enso_relsst.R
# =====================================================================

for (f in list.files("R", pattern = "\\.R$", full.names = TRUE)) source(f)
source(ccx_path("calibration", "lib_enso_index.R"))

ERS_KEY      <- "ersst_v6_monthly"            # MANIFEST row of the source grid
ERS_PSL_KEY  <- "nino34"                      # MANIFEST row of the shipped index
ERS_LF_YEARS <- EIX_LF_YEARS                  # 21, lib_enso_index.R
ERS_CMP_WIN  <- FORC_ENSO_DEMEAN_WIN          # 1948-2024, R/forcing.R
ERS_OUT      <- file.path("data", "forcing_enso_relsst.rds")

man <- utils::read.csv(ccx_path("data-raw", "downloads", "MANIFEST.csv"), stringsAsFactors = FALSE)
chk <- function(key) {
  row <- man[man$key == key, ]
  if (nrow(row) != 1) stop("MANIFEST has no single row for ", key)
  p <- ccx_path(row$file)
  if (!identical(digest::digest(file = p, algo = "sha256"), row$sha256))
    stop(row$file, " does not match its MANIFEST sha256")
  row
}
src <- chk(ERS_KEY); psl_row <- chk(ERS_PSL_KEY)
cat(sprintf("[1] %s and %s sha256 verified\n", basename(src$file), basename(psl_row$file)))

n34  <- eix_fixed_base(eix_ersst_box(EIX_BOX_N34,  path = ccx_path(src$file)))
trop <- eix_fixed_base(eix_ersst_box(EIX_BOX_TROP, path = ccx_path(src$file)))
m <- match(n34$year * 12L + n34$month, trop$year * 12L + trop$month)
stopifnot(!anyNA(m))
tv <- trop$value[m]
n  <- length(tv); h <- (ERS_LF_YEARS * 12L) %/% 2L
lp <- vapply(seq_len(n), function(i) mean(tv[max(1, i - h):min(n, i + h)]), numeric(1))
out <- data.frame(year = n34$year, month = n34$month,
                  nino34_grid = n34$value, trop_lp = lp,
                  nino34_relsst_lp = n34$value - lp,
                  partial = seq_len(n) <= h | seq_len(n) > n - h)

# ---- receipts --------------------------------------------------------
psl <- eix_nino34_shipped()
k <- match(psl$year * 12L + psl$month, out$year * 12L + out$month)
w <- !is.na(k) & psl$year >= ERS_CMP_WIN[1] & psl$year <= ERS_CMP_WIN[2]
g <- out$nino34_grid[k[w]]; s <- psl$value[w]
tr <- function(v, yy, mm) unname(coef(lm(v ~ I(yy + (mm - 0.5) / 12)))[2])
ow <- out$year >= ERS_CMP_WIN[1] & out$year <= ERS_CMP_WIN[2]
rcpt <- c(
  r_grid_vs_psl      = cor(g, s),
  slope_grid_on_psl  = unname(coef(lm(g ~ s))[2]),
  sd_psl             = sd(s),
  sd_grid            = sd(out$nino34_grid[ow]),
  sd_relsst_lp       = sd(out$nino34_relsst_lp[ow]),
  trend_psl_per_yr   = tr(s, psl$year[w], psl$month[w]),
  trend_grid_per_yr  = tr(out$nino34_grid[ow], out$year[ow], out$month[ow]),
  trend_relsst_per_yr = tr(out$nino34_relsst_lp[ow], out$year[ow], out$month[ow]),
  n_partial_in_win   = sum(out$partial & ow))
cat(sprintf("[2] %-20s %9.4f\n", names(rcpt), rcpt), sep = "")

attr(out, "provenance") <- list(
  built = format(Sys.Date()), script = "data-raw/build_enso_relsst.R",
  source = sprintf("%s (%s, accessed %s, sha256 %s)", src$file, src$source, src$accessed, src$sha256),
  citation = src$citation,
  method = sprintf(paste0("Nino 3.4 box (5S-5N, 170W-120W) minus %d-yr centred low-pass of the ",
                          "20S-20N mean; cos(lat) area weights; both anomalies on fixed base %d-%d; degC"),
                   ERS_LF_YEARS, EIX_CLIM_BASE[1], EIX_CLIM_BASE[2]),
  receipts = rcpt)
saveRDS(out, ccx_path(ERS_OUT))
cat(sprintf("[3] wrote %s: %d months %d-%02d .. %d-%02d\n", ERS_OUT, nrow(out),
            out$year[1], out$month[1], out$year[n], out$month[n]))
