#!/usr/bin/env python3
# Mutation harness for test-ms-kept-pair.R (the kept-pair fix, CHANGELOG 2026-10-08 c). Each mutation restores ONE way
# the driver used to keep (u, best) unpaired, or weakens the gate; the test file must FAIL. Original bytes restored
# after each run and md5-checked. Usage (repo root): python3 outputs/diagnostics/ms_kept_pair_20261008/mutate.py
import subprocess, sys, os, hashlib
LIB, DRV = "calibration/lib_ms_deadline.R", "calibration/run_dispersed_multistart.R"
MUT = {
 "M1_lib_returns_claim":   (LIB, "  list(par = step$par, value = v, claimed = step$value, gap = v - step$value)\n",
                                 "  list(par = step$par, value = step$value, claimed = step$value, gap = 0)\n"),
 "M2_restart_keeps_claim": (DRV, "    gain <- best - .kp$value; u <- .kp$par; best <- .kp$value\n",
                                 "    gain <- best - fit$value; u <- fit$par; best <- fit$value\n"),
 "M3_polish_on_claim":     (DRV, "      if (.kp$value < best) {\n", "      if (pc$value < best) {\n"),
 "M4_gate_relative":       (DRV, "dead_unpaired  <- !dead_nonfinite && !identical(.final_lp, -best)\n",
                                 "dead_unpaired  <- !dead_nonfinite && abs(.final_lp - (-best)) > MS_EVAL_TOL * max(1, abs(best))\n"),
 "M5_resume_unpaired":     (DRV, "  .kp <- ms_kept_pair(list(par = u, value = best), neg_lp); best <- .kp$value\n", "  .kp <- list(gap = 0)\n"),
 "M6_gaps_not_recorded":   (DRV, "            claim_gaps = claim_gaps, pairing = \"kept_pair\",\n", "            pairing = \"kept_pair\",\n"),
}
R = ('suppressMessages(library(testthat)); r <- test_file("tests/testthat/test-ms-kept-pair.R", reporter = "silent"); '
     'd <- as.data.frame(r); cat(sprintf("RESULT failed %d errors %d of %d expectations; failing tests: %s\\n", sum(d$failed), '
     'sum(d$error), sum(d$nb), paste(substr(d$test[d$failed > 0 | d$error], 1, 3), collapse = " ")))')
env = dict(os.environ, OMP_NUM_THREADS="1", OPENBLAS_NUM_THREADS="1", VECLIB_MAXIMUM_THREADS="1")
md5 = lambda f: hashlib.md5(open(f, "rb").read()).hexdigest()
orig = {f: open(f, "rb").read() for f in (LIB, DRV)}; m0 = {f: md5(f) for f in orig}
def run():
    out = subprocess.run(["nice", "-n", "10", "Rscript", "-e", R], capture_output=True, text=True, env=env).stdout
    l = [x for x in out.splitlines() if x.startswith("RESULT")]; return l[0] if l else "RESULT <none: the run died>"
ok = True; base = run()
print(f"{'M0_as_written':24s} {'PASSES' if 'failed 0 errors 0' in base else 'FAILS (harness invalid)'} | {base}")
for k, (f, a, b) in MUT.items():
    s = orig[f].decode()
    if s.count(a) != 1: print(k, "PATTERN NOT UNIQUE/ABSENT", s.count(a)); ok = False; continue
    open(f, "w").write(s.replace(a, b))
    try: res = run()
    finally: open(f, "wb").write(orig[f])
    caught = "failed 0 errors 0" not in res; ok &= caught
    print(f"{k:24s} {'CAUGHT' if caught else 'NOT CAUGHT'} | {res}"); sys.stdout.flush()
print("source restored (md5):", "yes" if all(md5(f) == m0[f] for f in orig) else "NO")
print("ALL CAUGHT" if ok else "A MUTATION SURVIVED")
