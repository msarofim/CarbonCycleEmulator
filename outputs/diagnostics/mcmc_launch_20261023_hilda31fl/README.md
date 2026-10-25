# The hilda31fl MCMC band: launch record (2026-10-23)

Marcus: "Mac, tonight (Recommended)". Starts follow the 10-13 ruling "Redraw until finite". CHANGELOG 2026-10-23 (n).

| file | what it is |
|---|---|
| `smoke_chain{1..4}.log` | `run_mcmc_check.R` at `2ec25511`, 300 iterations each (adapt 200, ckpt 100), 4 in parallel: every chain reproduces hilda31fl's stored logpost (-1050.120651, diff 0); chain 2 redraws twice (h_ml 75.79, 78.78: past the wall), chains 1, 3, 4 not at all; 1.3-1.5 min per 300 iterations (0.26-0.30 s/iteration) |
| `smoke_chains/chain_{1..4}.rds`, `MD5SUMS` | the smoke's chain files, copied 2026-10-24 from the frozen worktree's `outputs/mcmc_smoke_20261023_hilda31fl/` (`cmp`-identical) before the worktree was removed (Marcus: "Remove the MCMC worktree after copying the smoke chains"): 300 iterations, 5 kept each, seeds 20261002–05, chain 2 with 2 start redraws |
| `20261023_mcmc_hilda31fl_launch.sh` | the production launch, exactly resumable: 4 chains, n 2e5, adapt 3e4, thin 20, ckpt 500, seeds 20261001 + chain (recorded in each chain's provenance with the redraw count). The hilda31w launch with the tree, out dir and logs renamed |

Running in the frozen worktree `~/ccx_frozen/20261023_mcmc_hilda31fl` (at `2ec25511`; 79 download links + 3 tracked
files); chain files `outputs/mcmc_check_20261023_hilda31fl/chain_{1..4}.rds` there; logs
`~/ccx_frozen/20261023_mcmc_hilda31fl_chain{1..4}.out`; PIDs `~/ccx_frozen/20261023_mcmc_hilda31fl.pids` (the caffeinate
wrappers; wait with `kill -0`, never `pgrep -f`). Launched 2026-10-23 13:52 EDT; at the smoke's rate, 200k iterations take
about 15-17 h.
