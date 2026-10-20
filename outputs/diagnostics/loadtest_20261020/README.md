# Load test of the live CarboTope app, 2026-10-20

Marcus: "Run the load test." Target: the live app, revision `01a1467e` (deployed from `507d0a2`; 1 CPU, 1024 MB).
The local runs used `8b6fb21e`, whose app code is identical to `507d0a2` (only `app/DEPLOY.md` differs).

## Method

`loadtest.py` (stdlib Python, Chrome DevTools protocol). Each simulated student is a separate headless-Chrome
browser context, started at the same instant as the others, and does the classroom sequence: load the app, open
Futures → Pulse lab, press "Release the pulse" (default settings), open Known issues. Timed per student: connect,
first plot, pulse partition drawn, all nine Known-issues plots drawn. A disconnect or a 900 s timeout is recorded
as a failure. One unscored warm-up visit first; 30 s between steps. No RNG.

## Results on Connect Cloud (`loadtest_results.csv`, `loadtest.log`)

| students at once | completed | first plot (median / max) | pulse (median / max) | Known issues (median / max) |
|---|---|---|---|---|
| 1 | 1/1 | 2.0 / 2.0 s | 16.7 / 16.7 s | 3.5 / 3.5 s |
| 5 | 5/5 | 3.0 / 52.0 s | 39.9 / 64.7 s | 26.8 / 51.1 s |
| 10 | 0/10 | all connected, then 9 disconnected while the first page drew; 1 never connected | | |
| 20 | 0/20 | none connected in 900 s (Connect Cloud's "Loading..." page) | | |
| 30 | 0/30 | none connected in 900 s | | |

- At 5 students the work is served in turn: pulse times of 18, 34, 40, 49 and 65 s for one 17 s job each.
- The app was unavailable from the 10-student step (about 15:16 EDT) until about 16:03, after the test ended. A
  single student at 16:03 got normal timings (pulse 16.3 s). The 20- and 30-student steps probably prolonged the
  outage: their clients kept reloading Connect Cloud's loading page against a restarting app.

## Diagnosis

1. **Memory.** The same sequence against the app on the laptop (one R process; `local_*`):

   | | R process memory (RSS) |
   |---|---|
   | after start-up | 281 MB |
   | after the first full session (Known issues loads the gate kernels and caches) | ~600 MB |
   | peak during 10 students at once | 1,128 MB |
   | after 17 sessions, all closed | 1,144 MB |
   | second pass (5 + 10 more students): peak / end | 1,500 / 1,305 MB |

   About 30 MB per active student, and memory that does not come back when students leave (about 10 MB per
   session on the second pass). On a 1,024 MB container, 10 students at once cross the limit. Whether the
   retained memory is held session objects or R's allocator keeping its high-water mark is not separated here;
   the app has no explicit caches (`bindCache`, `memoise`, `<<-`: none found).
2. **Process scheduling.** The API shows Connect Cloud's settings for this content: up to 10 R processes
   (`sched_max_proc`), a new one when a process reaches 10 connections (`sched_max_conns` 20 × `sched_load_factor`
   0.5), 60 s for a process to start (`init_timeout`). A second process at 10 students adds another ~300 MB in the
   same 1 GB container. Either path exceeds 1 GB; the container logs (Connect Cloud content page, Logs) would show
   which.
3. **CPU.** One CPU serves everyone in turn, so the pulse lab's last student waits about (number of students) × 13–17 s.

## Not established

- The crash cause was not read from Connect Cloud's logs (the Browser pane is not signed in to Posit).
- The 20/30 steps never reached the app, so they measure the restart loop, not capacity.
- Local timings are on the M4, about 3× faster per pulse than Connect Cloud's CPU.
