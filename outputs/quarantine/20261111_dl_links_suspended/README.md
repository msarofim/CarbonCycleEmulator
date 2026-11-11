# Quarantined 2026-11-11: deploy bundle at `2bc18f62` whose Download links could stay disabled

**Files:** the deploy bundle `bundle_20261111_2bc18f62` (117 files, 7.4 MB), built by
`app/make_deploy_bundle.sh <out> 2bc18f62`. It is not in the repository: it was moved from `~/ccx_frozen/` to
`~/ccx_frozen/quarantine_20261111_dl_links_suspended/bundle_20261111_2bc18f62`, and the same command rebuilds it.
It was served locally only and never published.

**Bug:** batch A item A11 (CHANGELOG 2026-11-11 i) hides the Download line under a chart until the chart has an image
(`display: none` in `app/ui.R`). Shiny suspends an output it sees as hidden, and a suspended `downloadLink()` gets no
address. Shiny checks visibility when a tab is shown, which is usually before the chart draws, and nothing made it
check again after the chart drew. The link then stayed `disabled` with `href=""`, and a click did nothing.

**Symptoms:** a race. At 1440 x 900, 18 of the 54 links under drawn charts had no address, on four tabs (The Keeling
Curve, two charts on Where does the carbon go?, Isotope fingerprints, What pins down what?); the other tabs worked.
`check_live_pointer.py` reported its CSV line as empty, which is how it was found. Logs:
`outputs/diagnostics/review_20261111/bundle_2bc18f62/`.

**Replacement:** `app_dl_server()` (`app/R/downloads.R`) registers every download output with
`suspendWhenHidden = FALSE`; A11's CSS rule is unchanged. Gates: `test-app-review-20261111.R` A11b (mutation-tested,
`mutate_a11b.{sh,log}`) and `outputs/diagnostics/review_20261111/check_dl_links.py` in the browser. The bundle to
publish is built from the fix commit (CHANGELOG 2026-11-11 j).
