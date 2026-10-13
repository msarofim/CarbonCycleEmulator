# Run-time proof of CHANGELOG 10-12 (hh): the app's own objects at the canonical carry the WTC label's nuc_share.
ROOT <- "/Users/MarcusMarcus/Documents/2026/CodeProjects/CarbonCycleEmulator"; setwd(file.path(ROOT, "app"))
invisible(capture.output(suppressMessages(suppressWarnings(shiny::loadSupport(getwd(), renv = globalenv(), globalrenv = globalenv())))))
setwd(ROOT)
ok <- function(cond, what) { cat(sprintf("  [%s] %s\n", if (isTRUE(cond)) "PASS" else "FAIL", what)); invisible(cond) }
md <- readRDS(ccx_mode_file())
cat(sprintf("canonical %s | mode md5 %s | commit %s\n", CCX_MODE_CANONICAL, unname(tools::md5sum(ccx_mode_file())), ccx_git_stamp()))
want <- ccx_nuc_share_of(APP_PARAMS); cat("label's nuc_share (from APP_PARAMS):", want, "\n")
ok(identical(CCX_MODE_CANONICAL, "hilda31w"), "the app loaded hilda31w")
ok(want != "constant", "the label asks for a NON-constant share (otherwise an unstamped table would pass and the guard has no power)")
fit <- ccx_mode_params(CCX_MODE_CANONICAL)
for (n in c("bomb_share_NH", "seas_T_lag")) ok(isTRUE(all.equal(APP_SPIN$params[[n]], fit[[n]])),
   sprintf("%s in the app's spin-up = the mode's fit (%.4f vs %.4f)", n, APP_SPIN$params[[n]], fit[[n]]))
cat("1. the historical run (Keeling tab)\n")
F <- APP_HIST$forcing
ok(identical(attr(F, "nuc_share"), want), sprintf("APP_HIST forcing stamped '%s'", attr(F, "nuc_share")))
ok("nuc_share_NH" %in% names(F) && length(unique(round(F$nuc_share_NH, 6))) > 1, sprintf("its nuc_share_NH column is per-year (%d distinct values, %.3f-%.3f)",
   length(unique(round(F$nuc_share_NH, 6))), min(F$nuc_share_NH), max(F$nuc_share_NH)))
cat("2. the flux trace's row subset (APP_FLUX, pure-R core)\n")
k <- which(floor(F$t + 1e-9) == APP_HIST_YEARS[2])[1] - 1L
F2 <- F[(k + 1L):nrow(F), ]
ok(identical(attr(F2, "nuc_share"), want) && "nuc_share_NH" %in% names(F2), "a row subset keeps the stamp and the column")
ok(is.data.frame(APP_FLUX) && nrow(APP_FLUX) >= 1 && all(is.finite(unlist(APP_FLUX_NOW[sapply(APP_FLUX_NOW, is.numeric)]))), "APP_FLUX built, its last row finite")
cat("3. a futures build and a coupled run (futures / stylised / pulse tabs' choke point)\n")
Fv <- app_build_forcing("vvM", c(1750L, 2300L), prod_c14 = APP_SPIN$prod_c14)
ok(identical(attr(Fv, "nuc_share"), want), "app_build_forcing('vvM') stamped")
rr <- tryCatch(suppressWarnings(app_run_coupled(APP_SPIN, "vvM", c(1750L, 2300L))), error = function(e) e)
ok(!inherits(rr, "error"), if (inherits(rr, "error")) conditionMessage(rr) else
   sprintf("app_run_coupled('vvM') ran: CO2 2300 = %.2f ppm", mean(tail((rr$out$co2_NH + rr$out$co2_SH) / 2, 12))))
cat("4. MUTATIONS: the guard must refuse a table that dropped or changed the stamp\n")
Fs <- F; attr(Fs, "nuc_share") <- NULL
e1 <- tryCatch({ ccx_run_fast(APP_SPIN, Fs); NULL }, error = function(e) conditionMessage(e))
ok(!is.null(e1) && grepl("nuclear 14C share mismatch", e1), paste("unstamped table refused:", substr(e1 %||% "<RAN>", 1, 90)))
Fc <- F; attr(Fc, "nuc_share") <- "constant"
e2 <- tryCatch({ ccx_run_fast(APP_SPIN, Fc); NULL }, error = function(e) conditionMessage(e))
ok(!is.null(e2) && grepl("nuclear 14C share mismatch", e2), paste("'constant'-stamped table refused:", substr(e2 %||% "<RAN>", 1, 90)))
