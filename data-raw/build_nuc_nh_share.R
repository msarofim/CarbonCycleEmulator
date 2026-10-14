# =====================================================================
# build_nuc_nh_share.R -- the PER-YEAR Northern-Hemisphere share of the
# nuclear-industry 14C source, from the same 22-country files the model sums.
#
# WHY (citation rulings 2026-10-12, row 20). FORC_NUC_NH_SHARE = 0.95 was an
# uncited constant ("the 22 reporting countries are overwhelmingly NH"). Marcus:
# "Are we already refitting? If so, do the best option scientifically.
# Otherwise, 0.993." We are refitting, so the share is PER YEAR, built from the
# rows the model's GLOBAL source already sums (ccx_nuclear_c14_annual()): the
# split then stays consistent with the total year by year, reporting gaps
# included. It enters the objective ONLY under label hilda_csl3v0kaidgbemwtc
# (structure field `nuc_share_ts`); every registered mode keeps 0.95.
#
# THE HEMISPHERES. The files' reporting countries (Laemmel et al. 2025): Argentina
# and Brazil are the only Southern-Hemisphere ones (Atucha / Embalse; Angra). Every
# other country listed is NH. The SH list is a named constant and the build STOPS on
# any country it cannot place, so a new file cannot slip a SH reactor into the NH.
#
# ⚠ REPORTING GAPS ARE KEPT, NOT SMOOTHED: the model's global total is the same rows'
# sum, so a smoothed split would put SH 14C into years whose total has none.
# ⚠ THE GAPS ARE LONGER THAN THE LEDGER SAYS (measured 2026-10-12 e). The ledger's
# consequence column has "SH 0 in 2010 and 2023". The files carry SH (Argentina) rows
# for 1983-2006 and 2020-2021 only (Brazil 2020-2021 only), so the share is 1.0 in
# 1952-1982, 2007-2019 and 2022-2023 -- a FIFTEEN-year modern gap while Atucha / Embalse
# were operating. The same rows are missing from the model's global total, which is an
# undercount there too. Raised with Marcus; the build prints the years from the data.
#
# YEARS WITH NO SOURCE (the total is 0 or unreported): the share is undefined and
# PHYSICALLY irrelevant -- the source it splits is zero (R/forcing.R zeroes it
# outside the files' years). It is still needed as a NUMBER, because the 14C tag
# (R/c14_tag.R) injects through the nuclear column in any month, including future
# ones: those years HOLD the nearest year's share (`nh_share_filled`), which the
# forcing reads. Stated, not hidden: `filled` flags them.
#
# SOURCE. Laemmel T, Knaack T, Heckel A, Wenger A, Szidat S (2025), Compilation of
# nuclear industry's gaseous radiocarbon emissions from 1950 to 2023, Zenodo,
# doi:10.5281/zenodo.15034663 (CC-BY-4.0); fetched by data-raw/download_data.R [6b].
# Their MANIFEST.csv rows (keys nuc_*) were appended by hand on 2026-10-12, without
# re-running download_data.R; the access date there is the file mtime (2026-08-10),
# since the original was never recorded (CHANGELOG 2026-10-12 gg). Each file's sha256
# is ALSO stamped here, and the two agree.
# =====================================================================

for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)

NS_DIR     <- ccx_path("data-raw", "downloads", "nuclear14c")
NS_OUT     <- ccx_path("data", "forcing_nuc_nh_share.rds")
NS_SH      <- c("Argentina", "Brazil")
NS_NH      <- c("Bulgaria", "Canada", "China", "Czech Republic", "Finland", "France", "Germany",
                "Hungary", "Japan", "Korea South", "Lithuania", "Romania", "Slovakia", "Slovenia",
                "Spain", "Sweden", "Switzerland", "The Netherlands", "United Kingdom", "USA")
NS_POOLED_RULED <- 0.993          # the ledger's pooled share (row 20), reproduced below as a gate
NS_POOLED_TOL   <- 0.0005         # half a unit in its last quoted digit

fs <- list.files(NS_DIR, pattern = "csv$", full.names = TRUE)
stopifnot(length(fs) == 9L)
d <- do.call(rbind, lapply(fs, function(f) {
  x <- utils::read.csv2(f, stringsAsFactors = FALSE)
  data.frame(country = x$Country, year = suppressWarnings(as.integer(x$Year)),
             GBq = suppressWarnings(as.numeric(x$C14_tot_GBq)), file = basename(f))
}))
# EXACTLY the rows ccx_nuclear_c14_annual() keeps, so the split matches the model's total
d <- d[!is.na(d$year) & !is.na(d$GBq), ]
unk <- setdiff(unique(d$country), c(NS_SH, NS_NH))
if (length(unk)) stop("countries with no hemisphere: ", paste(unk, collapse = ", "))
d$sh <- d$country %in% NS_SH

tot <- aggregate(GBq ~ year, data = d, FUN = sum)
sh  <- aggregate(GBq ~ year, data = d[d$sh, ], FUN = sum)
yr  <- seq(min(tot$year), max(tot$year))
out <- data.frame(year = yr,
                  gbq_total = tot$GBq[match(yr, tot$year)],
                  gbq_sh    = sh$GBq[match(yr, sh$year)])
out$gbq_total[is.na(out$gbq_total)] <- 0
out$gbq_sh[is.na(out$gbq_sh)]       <- 0
out$nh_share <- ifelse(out$gbq_total > 0, 1 - out$gbq_sh / out$gbq_total, NA_real_)
# GATE: the total equals the model's own (ccx_nuclear_c14_annual sums the same rows; since
# 2026-10-14 it reads them from data/forcing_nuclear_c14.rds, so build that first)
mod <- ccx_nuclear_c14_annual()
k <- match(mod$year, out$year)
stopifnot(!anyNA(k), max(abs(out$gbq_total[k] * ccx_const("MOL_C14_PER_GBq") - mod$mol_per_yr)) == 0)
# filled: hold the nearest year with a defined share (ties -> the earlier year)
ok <- which(!is.na(out$nh_share))
near <- vapply(seq_len(nrow(out)), function(i) ok[which.min(abs(ok - i))], integer(1))
out$filled <- is.na(out$nh_share)
out$nh_share_filled <- out$nh_share[near]

pooled <- 1 - sum(out$gbq_sh) / sum(out$gbq_total)
cat(sprintf("%d-%d: per-year NH share %.4f-%.4f (min in %d); pooled %.4f (ruled %.3f); %d filled years (%s)\n",
            min(yr), max(yr), min(out$nh_share, na.rm = TRUE), max(out$nh_share, na.rm = TRUE),
            out$year[which.min(out$nh_share)], pooled, NS_POOLED_RULED, sum(out$filled),
            paste(out$year[out$filled], collapse = " ")))
cat(sprintf("SH = 0 (share 1.0) in reporting years: %s\n",
            paste(out$year[!out$filled & out$gbq_sh == 0], collapse = " ")))
if (abs(pooled - NS_POOLED_RULED) > NS_POOLED_TOL)
  stop(sprintf("pooled share %.4f does not reproduce the ledger's %.3f -- the files moved", pooled, NS_POOLED_RULED))

attr(out, "provenance") <- list(
  source = paste("Laemmel et al. (2025), Zenodo doi:10.5281/zenodo.15034663, CC-BY-4.0;",
                 "the nine files of data-raw/downloads/nuclear14c (download_data.R [6b])"),
  file_sha256 = vapply(fs, function(f) unname(tools::sha256sum(f)), ""),
  sh_countries = NS_SH, nh_countries = NS_NH, pooled_nh_share = pooled,
  ruling = "notes/citation_rulings_2026-10-12.md row 20; label hilda_csl3v0kaidgbemwtc (field nuc_share_ts)",
  script = "data-raw/build_nuc_nh_share.R", built = format(Sys.Date()))
names(attr(out, "provenance")$file_sha256) <- basename(fs)
saveRDS(out, NS_OUT)
cat(sprintf("written: %s\n", NS_OUT))
