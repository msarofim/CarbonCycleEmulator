# The end-of-run eval-rate fix (9b05553): smoke and mutation evidence

Marcus 2026-10-06: "Fix eval-rate line (Recommended)". CHANGELOG 2026-10-06 (d).

| file | what |
|---|---|
| `mutations_evalrate.sh`, `mutate.py` | six source mutations of the fix, each in a scratch worktree at `9b05553`, `test-ms-deadline.R` under a 120-s alarm, the file restored from HEAD |
| `mutations_evalrate.log` | baseline 50 passed; **6 of 6 CAUGHT as failures** (no errors to read around) |
| `smoke_driver_9b05553.log` | the committed driver end to end: #16's config, id 1, MAXIT 100, a 5-min WALL budget, from a frozen worktree |

**The smoke's reading.** The new line printed "eval rate 0.2140 s/eval, the slowest of 1 restart (fastest 0.2140)".
The driver's own pre-launch measurement, an independent instrument, was 0.2048 s/eval (median of 5; range
0.2016–0.2535), so the printed rate falls inside it. The replaced expression would have printed ~0.11 here
(60 × the normalised restart minutes / all 190 evals).

**The port gate was SKIPPED in the smoke, deliberately and as printed.** The tracked
`calibration/torch/port_targets.csv` is the 09-21 one (32 parameters; hilda29l as the incumbent), and the 10-05
copies name hilda34g. Either would stop the driver at start-up: "port targets were recorded on a 32-parameter build;
this build fits 33". With the file absent, the driver prints "PORT GATE SKIPPED … This run is NOT port-verified" and
runs. The smoke tests the print, not the port.
