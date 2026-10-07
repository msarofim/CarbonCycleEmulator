#!/usr/bin/env python3
# Mutation harness for test-promote-id.R (promote --id, CHANGELOG 2026-10-07 k). Each mutation breaks ONE property of
# the choice (calibration/lib_ms_promote.R) or its wiring (calibration/promote_multistart_mode.R); the test file must
# then FAIL. Each file's ORIGINAL BYTES are restored after each run (no git needed: the change may be uncommitted), and
# md5-checked at the end. Usage (repo root): python3 outputs/diagnostics/promote_id_gate_mutation/mutate.py
import subprocess, sys, os, hashlib
LIB, DRV = "calibration/lib_ms_promote.R", "calibration/promote_multistart_mode.R"
MUT = {
 "M1_id_ignored":       (LIB, "  if (is.na(id)) return(list(pick = top,", "  if (TRUE) return(list(pick = top,"),
 "M2_no_refusal":       (LIB, "  if (!isTRUE(s$converged) || isTRUE(s$out_of_time) || isTRUE(s$dead))\n", "  if (FALSE)\n"),
 "M3_dead_not_refused": (LIB, " || isTRUE(s$out_of_time) || isTRUE(s$dead))\n", " || isTRUE(s$out_of_time))\n"),
 "M4_default_min":      (LIB, "  top <- fin[[which.max(lp)]]\n", "  top <- fin[[which.min(lp)]]\n"),
 "M5_why_optional":     (DRV, "if (!is.na(PMM_ID) && (is.na(PMM_WHY)", "if (FALSE && !is.na(PMM_ID) && (is.na(PMM_WHY)"),
 "M6_promotes_top":     (DRV, "best <- CH$pick      #", "best <- CH$top       #"),
 "M7_gap_not_recorded": (DRV, "                       gap_to_best = CH$gap, why = PMM_WHY),", "                       why = PMM_WHY),"),
}
R = ('suppressMessages(library(testthat)); r <- test_file("tests/testthat/test-promote-id.R", reporter = "silent"); '
     'd <- as.data.frame(r); cat(sprintf("RESULT failed %d errors %d of %d expectations; failing tests: %s\\n", sum(d$failed), '
     'sum(d$error), sum(d$nb), paste(substr(d$test[d$failed > 0 | d$error], 1, 4), collapse = " ")))')
env = dict(os.environ, OMP_NUM_THREADS="1", OPENBLAS_NUM_THREADS="1", VECLIB_MAXIMUM_THREADS="1")
md5 = lambda f: hashlib.md5(open(f, "rb").read()).hexdigest()
orig = {f: open(f, "rb").read() for f in (LIB, DRV)}; m0 = {f: md5(f) for f in orig}
ok = True
out = subprocess.run(["Rscript", "-e", R], capture_output=True, text=True, env=env).stdout
base = [l for l in out.splitlines() if l.startswith("RESULT")]
print(f"{'M0_as_written':24s} {'PASSES' if base and 'failed 0 errors 0' in base[0] else 'FAILS (harness invalid)'} | {base[0] if base else '<none>'}")
for k, (f, a, b) in MUT.items():
    s = orig[f].decode()
    if s.count(a) != 1: print(k, "PATTERN NOT UNIQUE/ABSENT", s.count(a)); ok = False; continue
    open(f, "w").write(s.replace(a, b))
    try:
        out = subprocess.run(["Rscript", "-e", R], capture_output=True, text=True, env=env).stdout
    finally:
        open(f, "wb").write(orig[f])
    line = [l for l in out.splitlines() if l.startswith("RESULT")]
    res = line[0] if line else "RESULT <none: the run died>"
    caught = ("failed 0 errors 0" not in res)
    ok &= caught
    print(f"{k:24s} {'CAUGHT' if caught else 'NOT CAUGHT'} | {res}")
    sys.stdout.flush()
print("source restored (md5):", "yes" if all(md5(f) == m0[f] for f in orig) else "NO")
print("ALL CAUGHT" if ok else "A MUTATION SURVIVED")
