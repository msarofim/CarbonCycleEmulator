# =====================================================================
# build_nuclear_c14_source.R -- the nuclear-industry 14C source, summed per year,
# as a versioned data/ input (data/forcing_nuclear_c14.rds).
#
# WHY (Marcus 2026-10-14: "Promote to data/ .rds + stop() (Recommended)";
# CHANGELOG 2026-10-14 h, j). Until today ccx_nuclear_c14_annual() summed the nine
# CSVs in data-raw/downloads/nuclear14c AT RUN TIME, and when the directory was
# absent it WARNED and set the industrial source to ZERO. That was the only run-time
# read from data-raw/, and every copy of the tree that left data-raw/ out ran a
# different objective with no error:
#   - the 2026-09-01 Torch bundle (lib_run_inputs.R's header);
#   - three frozen worktrees (09-16, 09-24, 10-14; [[ccx_worktree_needs_downloads_linked]]);
#   - and, as DEPLOY.md was written, the PUBLIC APP: Δ14C NH -3.9 permil by 2024
#     (outputs/diagnostics/deploy_nuclear_absent_20261014/).
# data/ is tracked, so a worktree, a bundle and a deploy all carry this file, and
# the loader now STOPS without it.
#
# BIT-IDENTITY. The rows kept and the per-year sum are EXACTLY the old run-time
# reader's (ccx_nuclear_c14_sum_files(), R/forcing.R, which this script calls); the
# file stores GBq and the loader converts with ccx_const("MOL_C14_PER_GBq") as
# before, so mol_per_yr is the same double. Asserted below and in
# tests/testthat/test-nuclear-c14-source.R.
#
# COVERAGE is incomplete by construction (e.g. USA reports only 2010-2023), so the
# sum is a LOWER BOUND on the true industrial source -- stated in DATA.md.
#
# SOURCE. Laemmel T, Knaack T, Heckel A, Wenger A, Szidat S (2025), Compilation of
# nuclear industry's gaseous radiocarbon emissions from 1950 to 2023, Zenodo,
# doi:10.5281/zenodo.15034663 (CC-BY-4.0); fetched by data-raw/download_data.R [6b].
# Each file's sha256 is checked against data-raw/downloads/MANIFEST.csv (keys nuc_*)
# and stamped into the output; the build STOPS on any mismatch.
# =====================================================================

for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)

NC_DIR      <- ccx_path("data-raw", "downloads", "nuclear14c")
NC_OUT      <- ccx_path(FORC_NUC_C14_FILE)
NC_MANIFEST <- ccx_path("data-raw", "downloads", "MANIFEST.csv")
NC_N_FILES  <- 9L

fs <- list.files(NC_DIR, pattern = "csv$", full.names = TRUE)
if (length(fs) != NC_N_FILES)
  stop(sprintf("%d files in %s, expected %d", length(fs), NC_DIR, NC_N_FILES))

# GATE: every file is the one MANIFEST.csv records
man <- utils::read.csv(NC_MANIFEST, stringsAsFactors = FALSE)
sha <- vapply(fs, function(f) unname(tools::sha256sum(f)), "")
names(sha) <- basename(fs)
rel <- file.path("data-raw", "downloads", "nuclear14c", names(sha))
k <- match(rel, man$file)
if (anyNA(k)) stop("not in MANIFEST.csv: ", paste(rel[is.na(k)], collapse = ", "))
bad <- sha != man$sha256[k]
if (any(bad)) stop("sha256 differs from MANIFEST.csv: ", paste(names(sha)[bad], collapse = ", "))

out <- ccx_nuclear_c14_sum_files(NC_DIR)
attr(out, "provenance") <- list(
  source = paste("Laemmel et al. (2025), Zenodo doi:10.5281/zenodo.15034663, CC-BY-4.0;",
                 "the nine files of data-raw/downloads/nuclear14c (download_data.R [6b])"),
  units = "GBq 14C per year, summed over every reporting file; the loader converts to mol",
  file_sha256 = sha,
  manifest_keys = man$key[k],
  accessed = unique(man$accessed[k]),
  ruling = "Marcus 2026-10-14: \"Promote to data/ .rds + stop() (Recommended)\" (CHANGELOG 2026-10-14 j)",
  script = "data-raw/build_nuclear_c14_source.R", built = format(Sys.Date()))

# GATE: the round trip (.rds, then the loader) gives exactly the frame the old run-time
# reader returned, which was `out` converted in place. This checks the round trip only; that
# the MODEL is unchanged is checked against the pre-change build (CHANGELOG 2026-10-14 j) and,
# continuously, by the suite's stored-stream reproduce tests.
want <- data.frame(year = out$year, mol_per_yr = out$GBq * ccx_const("MOL_C14_PER_GBq"))
tmp <- tempfile(fileext = ".rds"); saveRDS(out, tmp)
if (!identical(ccx_nuclear_c14_annual(tmp), want)) stop("the round trip through the .rds is not bit-identical")

saveRDS(out, NC_OUT)
cat(sprintf("%d-%d, %d years, %.1f GBq in all (%.3f mol); written: %s\n",
            min(out$year), max(out$year), nrow(out), sum(out$GBq),
            sum(want$mol_per_yr), NC_OUT))
