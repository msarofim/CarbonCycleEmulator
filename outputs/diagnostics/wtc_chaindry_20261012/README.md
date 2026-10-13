# The WTC landing chain's ARMED DRY RUN (stage 1), 2026-10-12 22:33–22:57

**What ran:** `~/ccx_frozen/20261012ff_wtc_chain.sh dryrun`, started by `~/ccx_frozen/20261012ff_wtc_armed.sh` (stage 1)
when the wave `20261012ff` produced its first finished start file. It ran in its own detached worktree
`~/ccx_frozen/20261012ff_wtc_chaindry`, at the repo's HEAD **`bad9f9d`**. Both scripts are copied here byte-identical,
as they ran (md5 `b5e62a84…` chain, `13f515f7…` armed). The armed log at the end of stage 1 is `armed_stage1.out`.
CHANGELOG 2026-10-12 (ii).

**Verdict: every step returned rc 0**: collect → basins → promote LP → Hessian (`--update`) → WTC read → module
check → `checkz` (the ruled 0.1 σ) → ocean-climate driver → scorecard. This is the first time collect, basins and
promote have run under the label `hilda_csl3v0kaidgbemwtc`. The read's gates pass:
- each vector reproduces its stored logpost (diff 0);
- REF matches the wave's port target to 2.2e-11;
- REF's rows match the pricing's exactly;
- the label alone gives +106.9490, equal to the pricing's ALL row.

## ⛔ A PARTIAL WAVE: ONE start of 24. These numbers PREVIEW the landing; they are not its read.

Only **id 001** had finished: the incumbent start, hilda29e at its own model (0.90 / 2.0). It finished in
161 CPU-min. No dispersed draw had finished, and neither had the reference starts `cold` (id 0) or `new_basin` (id 2),
so this run has no survey and no basin comparison. Every number below is for that one start.

| quantity | id 001 | source |
|---|---|---|
| logpost (WTC objective) | −1054.5218, i.e. +8.43 over REF's port target −1062.9494 | `products/wtc_refit_read_*.log` §0–1 |
| likelihood vs REF | **+10.74** (−1015.79 vs −1026.53) | §1 |
| likelihood by group | bomb ¹⁴C +3.33, seasonal +3.45, ice cores +2.52, IntCal +0.91, CO₂ levels +0.46, ocean +0.07, δ¹³C levels −0.56, GCB rows −1.17 | §1 |
| `bomb_share_NH` | 0.8418 (legacy 0.90); Laplace sd 0.032; 2.2 sd from the nearer bound | §2 |
| `seas_T_lag` | **0.280 months** (legacy 2.0); Laplace sd 0.288; **within 1 sd of its lower bound 0** | §2 |
| corr in u, `seas_T_lag` | **`seas_lag_p_NH` +0.953**, `seas_lag_p_SH` +0.654 | §2 |
| corr in u, `bomb_share_NH` | `tau_ex` −0.307, `bomb_total` −0.062 (the ledger's partners) | §2 |
| largest moves (hilda29e's Laplace sd) | `seas_lag_p_NH` −5.84 sd, `seas_lag_p_SH` −3.89, `q10` +1.88, `npp_frac_NH` +1.79, `tau_ex` +1.13 | §3 |
| Hessian at the optimum | −H positive-definite, condition 3.54e5 | `DRYRUN_logs/hessian_id001.log` |
| futures, CO₂ 2300 (WTC − REF) | SSP5-8.5 +10.80 ppm, vvH +4.73 ppm (no ridge width measured for this objective) | §4 |
| net land climate effect 2015–2024 | −0.093 GtC/yr (REF −0.057); z +1.01 against GCB 2025 −0.8 ± 0.7 | §5 |
| **module check (ruled 0.1 σ)** | L +0.024 σ, s −0.077 σ, **w −0.470 σ ⇒ "a name moved MORE: to Marcus before any second pass"** | `DRYRUN_logs/checkz_id001.log` |
| module log-lik, optimum vs carried pins | **+0.146** (SSR 88.74 → 88.93; growth r 0.685 → 0.684) | `DRYRUN_logs/check_id001.log` §2 |
| scorecard GATE V | wtc PASS, sd 0.813 vs 0.933 ± 0.084, z −1.44 (hilda29e −1.62) | `DRYRUN_logs/scorecard.log` |
| other scorecard gates | the same verdicts as hilda29e: H, GL, 5, D fail; G, Q, 7, S, 6 pass | `DRYRUN_logs/scorecard.log` |

Two things the landing's read should look at, if the full wave repeats them:
1. **`seas_T_lag` vs `seas_lag_p_NH`.** The two are correlated +0.95 in u, and `seas_T_lag` sits near its floor.
   The new name may be largely trading off against an existing phase lag.
2. **The module check's verdict vs its likelihood.** `w` moves 0.47 σ, but the module's own optimum is only +0.15
   log-lik above the carried pins.

## Provenance stamps read `bad9f9d+dirty`. The cause is the chain's OWN writes in the scratch tree, not code.

In dryrun mode the chain:
- **overwrites the tracked `calibration/torch/port_targets.csv`**, by design, so that HEAD's canonical targets are
  replaced with the wave's;
- **writes untracked `DRYRUN_*` products into `calibration/output/`**, which is a `ccx_git_stamp()` path and is not
  gitignored.

#18 pass 2's landing shows the same pattern (`@58ef6fc+dirty` from the module check on,
`outputs/diagnostics/obj18p2_landing_20261008/`). In land mode the chain does not touch `calibration/torch/`. Only
`calibration/diag_wtc_refit_read.R` reads port targets, and it reads the WAVE's `port_targets_<label>.csv`, which
`land.sh` copies in. Checked by reading every reader of the file.

## Not copied (left in `~/ccx_frozen/20261012ff_wtc_chaindry`)

- the scratch copy of `start_001.rds` (the real one lands with the wave);
- the dry-run mode file `calibration/output/DRYRUN_refit_20261012_wtc_hilda_csl3v0kaidgbemwtc/` (+ its Hessian).

Neither belongs anywhere a mode lookup could find it. The worktree can be removed (`git worktree remove --force`) once
the landing is committed.
