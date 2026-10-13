# The hilda31w MCMC band: launch record (2026-10-13)

Marcus: "Launch on the Mac (Recommended)"; starts "Redraw until finite (Recommended)". CHANGELOG 2026-10-13 (j).

| file | what it is |
|---|---|
| `diag_mcmc_starts.R` | read-only, at `f6088ac`: reproduces the driver's 2x overdispersed starts for chains 1-4 and reports why each is non-finite. Chains 1-2 drew h_ml 78.6 / 82.9 m, past the P8 wall (75.48 m); 3-4 drew 56.0 / 58.9 m, finite |
| `smoke_chain{1..4}.log` | `run_mcmc_check.R` at `e83e228`, 300 iterations each (adapt 200, ckpt 100), 4 in parallel: chains 1-2 redraw twice, 3-4 not at all; every chain reproduces the stored logpost (diff 0); 0.26-0.42 s/iteration |
| `20261013_mcmc_hilda31w_launch.sh` | the production launch, exactly resumable: 4 chains, n 2e5, adapt 3e4, t0 1000, thin 20, ckpt 500, seeds 20261001 + chain (recorded in each chain's provenance with the redraw count) |

Running in the frozen worktree `~/ccx_frozen/20261013_mcmc_hilda31w` (at `e83e228`); chain files
`outputs/mcmc_check_20261013_hilda31w/chain_{1..4}.rds` there; logs `~/ccx_frozen/20261013_mcmc_hilda31w_chain{1..4}.out`;
PIDs `~/ccx_frozen/20261013_mcmc_hilda31w.pids` (wait with `kill -0`, never `pgrep -f`).
