# Interim look at the hilda31fl MCMC, 2026-10-23 ~17:16 EDT (40.5k–43k of 200k iterations)

Read-only. The four checkpoint files were copied out of the running worktree
(`~/ccx_frozen/20261023_mcmc_hilda31fl`, @`2ec25511`) to a scratch directory and read there; nothing in the worktree was
touched. Copied-file md5s: 1df0b711… / 7e68a54f… / 3c5250ef… / 057bc491….

- `read_interim_drop0.log`, `diag_interim_drop0.csv`: `calibration/read_mcmc_check.R --drop=0` on the copies (main @`5dbf9c42`
  plus the uncommitted `RB_COV_EMIS` line). The pooled draws it wrote are NOT kept: they are partial chains and must never
  feed a band.
- `interim_perchain.R`, `interim_perchain.log`: per-chain 5/50/95 % and the median in each third of the window, for eight
  names on the parameter scale.

What it shows, at about 10.5k post-adaptation iterations (525–650 kept per chain):

- Not converged: R-hat above 1.01 on all 32 quantities, bulk ESS 7–28. Too early to judge.
- Chain 4 has already reached `seas_T_lag` 2.2 months (95 % point), the ridge that chain 4 walked at hilda31w from ~50k.
  Chains 1–3 sit at 0.12–0.26 (medians).
- Chain 2 sits higher on `beta_max` / `fert_k` (medians 2.55 / 815) than chains 1, 3, 4 (1.92–1.97 / 533–664). These two are
  the worst R-hats (1.57, 1.49) with `ndep_ret` (1.51).
- `h_ml`'s u-space sd is 5.1× the Laplace sd (2.94× in the full hilda31w read); its median by chain is 56–64 m against the
  mode's 69.7.

The full read follows the hilda31w precedent (CHANGELOG 2026-10-14 a, b) once the chains land.
