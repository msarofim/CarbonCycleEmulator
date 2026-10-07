#!/usr/bin/env python3
# Mutation harness for test-iav-redesign.R (objective #18's build, 2026-10-07). Each mutation breaks ONE property of
# the built code in the live source; the test file must then FAIL. The source is restored from git after each run.
# Usage (repo root): python3 outputs/diagnostics/obj18_build_gate_mutation/mutate.py
import subprocess, sys, os
MUT = {
 "M1_err_drops_switch": ("R/likelihood.R",
   '  if (!is.null(p[["gcb_ocean_lowpass_df"]])) err$gcb_ocean_lowpass_df <- p[["gcb_ocean_lowpass_df"]]\n', ''),
 "M2_row_ignores_switch": ("R/likelihood.R",
   '      if (!is.null(err[["gcb_ocean_lowpass_df"]]))\n        row_o <- row_o',
   '      if (FALSE)\n        row_o <- row_o'),
 "M3_label_drops_index": ("R/calibrate.R",
   '  blk$enso_index           <- CCX_ENSO_INDEX_CODES[["detrend"]]\n', ''),
 "M4_cost_at_land_sd": ("R/likelihood.R",
   'err[["gcb_ocean_lowpass_df"]], LIK_GCB_OCEAN_SD)', 'err[["gcb_ocean_lowpass_df"]], LIK_GCB_LAND_SD * LIK_LAND_SINK_INFLATE)'),
 "M5_wrong_df": ("R/likelihood.R",
   '        row_o <- row_o + ccx_land_highpass_cost(tgt_o - g$ocean, g$year,\n                                                err[["gcb_ocean_lowpass_df"]]',
   '        row_o <- row_o + ccx_land_highpass_cost(tgt_o - g$ocean, g$year,\n                                                4L'),
 "M6_label_index_relsst": ("R/calibrate.R",
   'CCX_ENSO_INDEX_CODES[["detrend"]]\n  blk$gcb_ocean_lowpass_df', 'CCX_ENSO_INDEX_CODES[["relsst_lp"]]\n  blk$gcb_ocean_lowpass_df'),
}
R = ('suppressMessages(library(testthat)); r <- test_file("tests/testthat/test-iav-redesign.R", reporter = "silent"); '
     'd <- as.data.frame(r); cat(sprintf("RESULT failed %d errors %d of %d expectations; failing tests: %s\\n", sum(d$failed), '
     'sum(d$error), sum(d$nb), paste(substr(d$test[d$failed > 0 | d$error], 1, 4), collapse = " ")))')
env = dict(os.environ, OPENBLAS_NUM_THREADS="1", VECLIB_MAXIMUM_THREADS="1")
ok = True
for k, (f, a, b) in MUT.items():
    s = open(f).read()
    if s.count(a) != 1: print(k, "PATTERN NOT UNIQUE/ABSENT", s.count(a)); ok = False; continue
    open(f, "w").write(s.replace(a, b))
    try:
        out = subprocess.run(["Rscript", "-e", R], capture_output=True, text=True, env=env).stdout
    finally:
        subprocess.run(["git", "-C", ".", "checkout", "--", f], check=True)
    line = [l for l in out.splitlines() if l.startswith("RESULT")]
    res = line[0] if line else "RESULT <none: the run died>"
    caught = ("failed 0 errors 0" not in res)
    ok &= caught
    print(f"{k:24s} {'CAUGHT' if caught else 'NOT CAUGHT'} | {res}")
    sys.stdout.flush()
d = subprocess.run(["git", "-C", ".", "diff", "--stat", "R/"], capture_output=True, text=True).stdout
print("source restored:", "yes" if not d.strip() else "NO\n" + d)
print("ALL CAUGHT" if ok else "A MUTATION SURVIVED")
