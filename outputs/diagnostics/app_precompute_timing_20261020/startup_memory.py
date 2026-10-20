"""Resident memory of the app's WHOLE process tree during a cold start (2026-10-20).

Since 2026-10-20 the C++ core compiles in a background R process (R/cpp.R ccx_cpp_prebuild()), so during the
first seconds the app is the R process PLUS that child and the compiler it runs. The child is started with
system2(wait = FALSE), so it is DETACHED (re-parented to launchd), not a descendant: it is found by its command
line, which carries the build directory's name (PREBUILD_TAG). This samples `ps` every SAMPLE_S for WINDOW_S
after the process starts and records the R process's own RSS and the total over both trees.
No browser: it measures start-up only.

Usage:  startup_memory.py <bundle_dir> <app_port> <out_csv>
"""
import sys, time, subprocess, csv

SAMPLE_S = 0.1
WINDOW_S = 8.0
PREBUILD_TAG = "ccx_cpp_prebuild"     # in the background build's command line (R/cpp.R ccx_cpp_prebuild())
bundle, port, out_csv = sys.argv[1], int(sys.argv[2]), sys.argv[3]


def table():
    rows = subprocess.check_output(["ps", "-Ao", "pid=,ppid=,rss=,command="]).decode().splitlines()
    t = {}
    for r in rows:
        p = r.split(None, 3)
        if len(p) >= 3: t[int(p[0])] = (int(p[1]), int(p[2]), p[3] if len(p) > 3 else "")
    return t


def tree_rss(roots, t):
    kids = {}
    for pid, (ppid, _, _) in t.items(): kids.setdefault(ppid, []).append(pid)
    tot, names, stack, seen = 0, [], list(roots), set()
    while stack:
        p = stack.pop()
        if p in seen: continue
        seen.add(p)
        if p in t:
            tot += t[p][1]; names.append(t[p][2].split()[0].rsplit("/", 1)[-1])
        stack += kids.get(p, [])
    return tot / 1024, names


pids_before = set(table())             # a build tag already running belongs to some other process
t0 = time.time()
r = subprocess.Popen(["Rscript", "-e", f"shiny::runApp('{bundle}', port = {port}, host = '127.0.0.1', "
                      "launch.browser = FALSE)"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
samples = []
try:
    while time.time() - t0 < WINDOW_S:
        t = table()
        own = t.get(r.pid, (0, 0, ""))[1] / 1024
        bg = [pid for pid, (_, _, cmd) in t.items() if PREBUILD_TAG in cmd and pid not in pids_before]
        tot, names = tree_rss([r.pid] + bg, t)
        samples.append({"t_s": round(time.time() - t0, 2), "r_rss_mb": round(own, 1), "tree_rss_mb": round(tot, 1),
                        "n_procs": len(names), "procs": " ".join(sorted(set(names)))})
        time.sleep(SAMPLE_S)
finally:
    r.terminate()
    try: r.wait(10)
    except subprocess.TimeoutExpired: r.kill()
with open(out_csv, "w", newline="") as f:
    w = csv.DictWriter(f, fieldnames=list(samples[0])); w.writeheader(); w.writerows(samples)
pk = max(samples, key=lambda s: s["tree_rss_mb"])
print(f"peak tree RSS {pk['tree_rss_mb']} MB at {pk['t_s']} s ({pk['procs']}); "
      f"R alone at end {samples[-1]['r_rss_mb']} MB; tree at end {samples[-1]['tree_rss_mb']} MB")
