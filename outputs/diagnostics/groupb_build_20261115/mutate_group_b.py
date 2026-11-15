"""Mutation test for the group B gates (2026-11-15). Each mutant breaks one behaviour the gates guard; the named test
file must then FAIL. Every file is restored with `git checkout --` after its mutant, so run it on a clean tree and with
no app process reading the checkout. Usage (repo root): python3 -I outputs/diagnostics/groupb_build_20261115/mutate_group_b.py
"""
import subprocess, sys, os
ROOT = os.getcwd()
G = "tests/testthat/test-app-review-20261115.R"
C = "tests/testthat/test-app-review-copy.R"
MUTANTS = [
    ("B19 card lag off the shared peak", "app/R/review.R", "RV_GROWTH_ENSO_LAG_MO <- 11L", "RV_GROWTH_ENSO_LAG_MO <- 5L", G),
    ("B19 another smooth than the tab's", "app/R/plots.R", "GROWTH_ANOM_DF <- 3L", "GROWTH_ANOM_DF <- 4L", G),
    ("B19 card text's overshoot claim", "app/R/review.R", '"three of the five largest overshoots are 1991\\u20131993, after Pinatubo.",', '"the largest overshoots are 1991\\u20131993, after Pinatubo.",', G),
    ("B19 plain's fraction", "app/R/review.R", '"wobble in CO₂ growth is only about two thirds of the observed one."),', '"wobble in CO₂ growth is only about three quarters of the observed one."),', G),
    ("B4 threshold", "app/global.R", "TAKEAWAY_PPM_SMALL <- 1\n", "TAKEAWAY_PPM_SMALL <- 0.1\n", G),
    ("B2 his wording", "app/global.R", 'sprintf("drop another %d%%", -pC)', 'sprintf("drop %d%%", -pC)', G),
    ("B7 count", "app/R/params_meta.R", 'sum(set == "fitted"), sum(set == "held")', 'sum(set == "held"), sum(set == "held")', G),
    ("B14 note year", "app/global.R", "AF_NOTE_BEFORE <- 1900L", "AF_NOTE_BEFORE <- 1850L", G),
    ("B12 hemisphere ignored", "app/R/plots.R", 'hs <- switch(hemi, both = c("NH", "SH"), NH = "NH", SH = "SH")', 'hs <- "NH"', G),
    ("B15 caption from the window", "app/R/plots.R", "min(d$year), max(d$year)))) +", "yr_range[1], yr_range[2]))) +", G),
    ("B22 a reader left out", "app/global.R", 'APP_BUILD_RESULT_IDS <- c("f_takeaway", "f_plot", "f_notes")', 'APP_BUILD_RESULT_IDS <- c("f_takeaway", "f_plot")', G),
    ("B22 hidden slider grays", "app/server.R", "build_inputs <- reactive(app_build_inputs(input))",
     "build_inputs <- reactive(list(s_kind = input$s_kind, s_bg = input$s_bg, s_rate = input$s_rate, s_zero_year = input$s_zero_year))", G),
    ("B22 Pulse lab button not watched", "app/ui.R", "$(document).on('click', '#s_go, #p_go', function () {", "$(document).on('click', '#s_go', function () {", G),
    ("B10 isotope note gone", "app/ui.R", "        unit_note_permil(),   # group B B10: the takeaway prints", "        NULL,   # group B B10: the takeaway prints", G),
    ("B17 breakpoint", "app/ui.R", "APP_STACK_MAX_PX <- 991.98", "APP_STACK_MAX_PX <- 767.98", G),
    ("B9.6 range order", "app/R/plots_review.R", 'rv_signed("%.2f", e$ccx[["min"]]),\n           rv_signed("%.2f", e$ccx[["max"]])',
     'rv_signed("%.2f", e$ccx[["max"]]),\n           rv_signed("%.2f", e$ccx[["min"]])', G),
    ("B20 card 7 old wording", "app/R/review.R", '"2009). The data are more consistent with the literature value.",', '"2009). The data prefer the literature value.",', C),
]
def run(test):
    r = subprocess.run(["Rscript", "-e", f'r <- as.data.frame(testthat::test_file("{test}", reporter = "silent", stop_on_failure = FALSE)); cat("RESULT", sum(r$failed) + sum(r$error), "\\n")'],
                       capture_output=True, text=True, env=dict(os.environ, OPENBLAS_NUM_THREADS="1", VECLIB_MAXIMUM_THREADS="1"))
    line = [l for l in r.stdout.splitlines() if l.startswith("RESULT")]
    return int(line[0].split()[1]) if line else -1
if subprocess.run(["git", "-C", ROOT, "diff", "--quiet", "--", "app"]).returncode != 0:
    sys.exit("REFUSING: app/ has uncommitted changes (each mutant is restored with git checkout)")
caught = 0
for name, f, old, new, test in MUTANTS:
    src = open(f).read()
    if src.count(old) != 1: print(f"SKIP  {name}: pattern found {src.count(old)} times"); continue
    open(f, "w").write(src.replace(old, new))
    try: bad = run(test)
    finally: subprocess.run(["git", "-C", ROOT, "checkout", "--", f])
    ok = bad > 0; caught += ok
    print(f"{'CAUGHT' if ok else 'MISSED'}  {name}  ({bad} failures/errors in {os.path.basename(test)})", flush=True)
print(f"\n{caught}/{len(MUTANTS)} mutants caught")
