#!/usr/bin/env python3
# Mutation harness for test-ms-seed.R (the seeded slots + the duplicate refusal, CHANGELOG 2026-10-07 m). Each mutation
# breaks ONE property of calibration/lib_ms_seed.R or its wiring (the driver, the collector); the test file must then
# FAIL. M2 is also run through the DRIVER (start_harness.R, #18, id 3): with the encoder check gone, the driver's own
# duplicate refusal must stop the task. Each file's ORIGINAL BYTES are restored after each run and md5-checked at the end.
# Usage (repo root): python3 outputs/diagnostics/ms_seed_fix_20261007/mutate.py
import subprocess, sys, os, hashlib
LIB, DRV, COL = "calibration/lib_ms_seed.R", "calibration/run_dispersed_multistart.R", "calibration/collect_dispersed_multistart.R"
D = "outputs/diagnostics/ms_seed_fix_20261007"  # run_harness.sh needs CCX_SCRATCH set (any scratch dir)
MUT = {
 "M1_l2_ignores_free":     (LIB, "} else if (isTRUE(limb_on) && MS_ENSO_L2_NAME %in% free) {", "} else if (isTRUE(limb_on)) {"),
 "M2_no_encoder_check":    (LIB, "  if (identical(u, u_ref))\n", "  if (FALSE)\n"),
 "M3_refusal_noop":        (LIB, "    if (identical(unname(v), unname(u)))\n", "    if (FALSE)\n"),
 "M4_land_ignores_free":   (LIB, "    lf <- intersect(MS_ENSO_LAND_PAIR, free)\n", "    lf <- MS_ENSO_LAND_PAIR\n"),
 "M5_label_typed":         (LIB, "    c$lab <- if (length(m) && !length(notes)) c$lab\n", "    c$lab <- if (TRUE) c$lab\n"),
 "M6_driver_no_refusal":   (DRV, "ms_assert_distinct_start(MS_ID, st$u, stats::setNames(lapply(MS_FIXED_IDS, ms_fixed_u), MS_FIXED_IDS))\n", "\n"),
 "M7_driver_pins_as_free": (DRV, "free = CCX_PARAM_NAMES, pinned", "free = c(CCX_PARAM_NAMES, names(MS_PINS)), pinned"),
 "M8_class_from_id":       (DRV, "            start_class = st$class,\n", "            start_class = if (MS_ID >= MS_DISPERSED_FROM) \"dispersed\" else if (MS_ID %in% MS_SEED_IDS) \"seeded\" else \"reference\",\n"),
 "M9_collector_bench":     (COL, "kB <- which(ids %in% CO_BENCH_IDS & !co_drawn)\n", "kB <- which(ids %in% CO_BENCH_IDS)\n"),
}
R = ('suppressMessages(library(testthat)); r <- test_file("tests/testthat/test-ms-seed.R", reporter = "silent"); '
     'd <- as.data.frame(r); cat(sprintf("RESULT failed %d errors %d of %d expectations; failing tests: %s\\n", sum(d$failed), '
     'sum(d$error), sum(d$nb), paste(substr(d$test[d$failed > 0 | d$error], 1, 4), collapse = " ")))')
env = dict(os.environ, OMP_NUM_THREADS="1", OPENBLAS_NUM_THREADS="1", VECLIB_MAXIMUM_THREADS="1")
md5 = lambda f: hashlib.md5(open(f, "rb").read()).hexdigest()
orig = {f: open(f, "rb").read() for f in (LIB, DRV, COL)}; m0 = {f: md5(f) for f in orig}
ok = True
def run_tests():
    out = subprocess.run(["nice", "-n", "10", "Rscript", "-e", R], capture_output=True, text=True, env=env).stdout
    line = [l for l in out.splitlines() if l.startswith("RESULT")]
    return line[0] if line else "RESULT <none: the run died>"
base = run_tests()
print(f"{'M0_as_written':24s} {'PASSES' if 'failed 0 errors 0' in base else 'FAILS (harness invalid)'} | {base}")
for k, (f, a, b) in MUT.items():
    s = orig[f].decode()
    if s.count(a) != 1: print(k, "PATTERN NOT UNIQUE/ABSENT", s.count(a)); ok = False; continue
    open(f, "w").write(s.replace(a, b))
    try:
        res = run_tests()
        drv = ""
        if k == "M2_no_encoder_check":   # ...and through the DRIVER: its refusal must stop #18's id 3
            subprocess.run(["bash", f"{D}/run_harness.sh", "obj18", "new", "3"], capture_output=True, text=True, env=env)
            log = open(f"{D}/start_obj18_new_003.log").read()
            drv = " || DRIVER: " + ("REFUSED: " + [l for l in log.splitlines() if "DUPLICATE START" in l][0].strip()[:90]
                                    if "DUPLICATE START: id 3's start vector is identical() to id 1's" in log else "NOT REFUSED")
            if "NOT REFUSED" in drv: ok = False
    finally:
        open(f, "wb").write(orig[f])
    caught = ("failed 0 errors 0" not in res)
    ok &= caught
    print(f"{k:24s} {'CAUGHT' if caught else 'NOT CAUGHT'} | {res}{drv}")
    sys.stdout.flush()
# the harness record for #18 id 3 was overwritten by M2's driver run: restore it from the unmutated driver
subprocess.run(["bash", f"{D}/run_harness.sh", "obj18", "new", "3"], capture_output=True, text=True, env=env)
print("source restored (md5):", "yes" if all(md5(f) == m0[f] for f in orig) else "NO")
print("ALL CAUGHT" if ok else "A MUTATION SURVIVED")
