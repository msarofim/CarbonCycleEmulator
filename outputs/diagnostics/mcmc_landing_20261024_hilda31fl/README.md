# The hilda31fl MCMC landing chain, armed 2026-10-23

The script `20261024_land_hilda31fl_armed.sh` (a copy; the running one is `~/ccx_frozen/20261024_land_hilda31fl_armed.sh`)
waits for the four hilda31fl chains (`~/ccx_frozen/20261023_mcmc_hilda31fl`, @`2ec25511`, launched 10-23 13:52) and
then runs handoff 10-23 §4.1 in the frozen worktree `~/ccx_frozen/20261024_land_hilda31fl` (@`d1e3c476`,
`data-raw/downloads` linked per file, 79 links + 3 tracked).

- **Wait:** `kill -0` on each PID in `~/ccx_frozen/20261023_mcmc_hilda31fl.pids`, plus a check that the PID still runs
  `run_mcmc_check.R`. No `pgrep` loop.
- **Phase 1** (reports only; the handoff's prescribed reads): each chain at iteration 200 000 or STOP; snapshot into the
  frozen tree's `outputs/mcmc_check_<landing date>_hilda31fl_200k/` (`cp -p`, `cmp`, `MD5SUMS`, chain logs and launch script in
  `logs/`); `read_mcmc_check.R --drop=0`; `diag_mcmc_identifiability.R`.
- **Phase 2** runs only if `~/ccx_frozen/20261024_land_hilda31fl.RULED` exists. It holds Marcus's ruling verbatim, with
  `DROP=` and `THIN=` lines that the script reads with `grep` and never sources. It then runs the read at those settings,
  the band (`build_futures_ribbons.R`, 8 cores, then `diag_mcmc_band_by_chain.R --laplace=none` and `diag_mcmc_drift.R` on
  the five worst R-hats) and, in parallel on one core, the tie stability (`diag_cmap_posterior_spread.R`, 100 draws).
  Nothing is promoted.
- After landing, the snapshot and products are copied into this repo (`cmp`-checked) and committed. The frozen tree is then
  removed.

`smoke_20261023/` holds the smoke run of every step on interim checkpoint copies (40.5k–43k iterations; 2100 pooled
draws; 20 at thin 100, which feed the band; 2 tie draws) at `d1e3c476`. It tests the plumbing only. Its numbers are partial
chains and are not results.

- The first pass (`smoke_landing.sh`, `smoke_landing.out`) stopped at the drift step: `diag_mcmc_drift.R` requires `h_ml` in
  `--names` (its floor share reads it), and the five worst R-hats did not include it. The armed script now passes `h_ml` plus
  the four worst other R-hats. The drift step was re-run by hand with that line's output (`drift.out`, rc 0), then the tie
  spread (`spread.out`, rc 0).
- Gates: identifiability's logpost GATE diff 0; the tie spread's STEP, MAP, JOIN and LP gates all diff 0, at 21.8 s per map
  (so 100 draws is about 37 min on one core); the band's central line matched the app's runs with max |diff| 0.
- The smoke's products were moved out of the frozen tree (to the session scratch directory) before arming, so the real run
  writes into a clean `outputs/`.
- Armed 2026-10-23 17:25:46, PID 10464 (`~/ccx_frozen/20261024_land_hilda31fl_armed.pid`), log
  `~/ccx_frozen/20261024_land_hilda31fl_armed.out`.
