# HANDOFF 2026-10-09 — the `hilda29e` MCMC chains are EXTENDING to 200k; the 200k landing is ARMED; NEXT: read what it lands, then Marcus rules on shipping

**Supersedes** `notes/handoff_2026-10-08b_mcmc_band_running.md`. Its §3 items 1–3 are DONE (the 50k and 100k reads, both bands, both per-chain tests). Its item 4 was reported, and Marcus ruled (below). Items 5–6 still apply unchanged.
Written on Marcus's request ("Yes, write the handoff note"), 2026-10-09 ~06:20 EDT, while the extended chains run.

**Start here.**
1. CHANGELOG **2026-10-09 (b)**, **(a)**, then **2026-10-08 (l)**.
2. Memory: `laplace_fails_on_fertilisation_ridge` (its 10-08 l / 10-09 a / 10-09 b paragraphs carry this arc), `rhat_denominator_forgives`, `ccx_hilda29e_adopted`.
3. `~/.claude/CLAUDE.md` and this repo's `CLAUDE.md`.

## 1. What was done this session (rulings verbatim)

| Ruling (Marcus) | Outcome |
|---|---|
| "Read handoff … and continue work" | **The 50k preview band, chain by chain** (CHANGELOG 10-08 l): CO₂ between-chain range max **7.08 ppm**, **46 %** of the width (median 32 %), against `hilda33d` stage 1's 3.42 ppm / 29 % over an equal window. Not widening. **Two driver bugs fixed on the way:**<br>(a) `diag_mcmc_band_by_chain.R` silently paired the band with `hilda33d`'s Laplace band AND central line. It now has a same-mode gate and `--laplace=none` (`155bc28`).<br>(b) `build_futures_ribbons.R` hard-coded "Gaussian approximation" and "covariance predates the flip", both false for MCMC draws at `hilda29e`. The label now follows the draws' source, and `RB_COV_EMIS` is keyed by mode (`830d620`). The preview was quarantined to `outputs/quarantine/20261008_ribbons_mcmc_provenance_label/`; its numbers are valid.<br>**Full suite at `3c754ab`:** 7082 passed, 2 failed (card 4's two, by design), 0 errors, 3 standing skips. The +45 since `1f9f904` is accounted for exactly. |
| (the 100k landing, armed under 10-08 j's "MCMC band") | **The 100k read** (CHANGELOG 10-09 a, `ba08df9`): NOT converged. R-hat max **1.098** (`h_ml`), 21 of 30 > 1.01, min bulk ESS 42.<br>Band: CO₂ between-chain max **5.31 ppm / 43 %** (median 1.81 / 21 %); cell R-hat max 1.077. vvH 2150 812.2 / 822.4 / 834.6.<br>From 50k: width ×1.06, medians within 0.6 ppm. Late/early width 1.08 in every cell.<br>⭐ **`h_ml` drifts INTO its ruled 42.5 m floor** (near-floor draws 4.8 % → 24.8 %; logpost −1.48 with it) **but is worth only +0.58 ppm per posterior sd at vvH 2150.** The band's spread is `ndep_ret` (vvLN −2.6 ppm/sd) and `beta_max` (vvH −4.7) wandering. Source: `calibration/diag_mcmc_drift.R` (`d2bd671`). |
| **"Extend to 200k (Recommended)"; "Thin ×2 within chain (Recommended)"** | ⚠ **The resume guard REFUSED a changed `--n`.** The old handoff's "raise `--n`" had never been tried. Fixed in `00b1c09`: a COMPLETE, post-adaptation chain extends, and the extension is recorded in `provenance$extended`. **Shown bit-identical on a short chain** (all 14 state fields). Shrinking n and extending a mid-run chain are both refused.<br>`read_mcmc_check.R --pool-thin=k` thins the POOLED draws only; the diagnostics read every sample (`b004ef1`). Verified against the 100k snapshot; an off-by-one grid stops the drift driver's join.<br>**Extension launched 06:10 EDT. The 200k landing is armed** (§2). |

## 2. Where things stand NOW

**A. The chains: EXTENDING 100k → 200k. Nothing shipped; `APP_RIBBONS_HOLD` still set.**
- Frozen worktree `~/ccx_frozen/20261008j_mcmc`, **moved `1e00851` → `00b1c09`**. Only `run_mcmc_check.R` and `data/ocean_climate_card.rds` differ between those commits, so the objective is unchanged. All four resume gates reproduced the mode's logpost (diff 0.00e+00).
- Launcher `~/ccx_frozen/20261009a_mcmc_extend_launch.sh` (`--n=200000`, otherwise the 10-08 j settings).
- **R PIDs 89223–89226** (`~/ccx_frozen/20261009a_mcmc_extend.pids`); parent 1, each under `caffeinate -i -s`.
- Logs are APPENDED to `~/ccx_frozen/20261008j_mcmc_chain{1..4}.out`. ⚠ They also hold the 100k run's lines: grep `/200000`, never a bare iteration number. (A wait on `iter 10[1-9]` matched an old "10500/100000" line this session.)
- ⚠ **CONTENTION.** Another session's job started ~06:08: `slr-refresh` MAGICC + Julia (`_frozen_302d_20261009.py`), plus a VM at ~170 % CPU. Load was ~30–40. The chains run **~0.62 s/iteration** (0.30 uncontended), so they finish **~23:30 EDT 10-09** if the load holds, ~14:30 if it clears. Left alone: it is not this session's.
- Exactly resumable: re-running the extension launcher continues each chain.

**B. The 200k landing: ARMED** (`outputs/diagnostics/mcmc_200k_landing_20261009/land.sh`, `0635ed7`; bash PID in `~/ccx_frozen/20261009b_land200k.pid`, 91023 at writing). Log: that directory's `land.log`, untracked until committed. Its steps:
1. wait on the four PIDs with `kill -0`;
2. require "COMPLETE: 200000 iterations" in every log, or stop (rc 2);
3. snapshot to `outputs/mcmc_check_20261009_hilda29e_200k/`, md5-checked against the live files;
4. `read_mcmc_check.R --pool-thin=2`: window (30000, 200000], 8500 kept/chain, 4250 pooled/chain → `pooled_u_thin2.rds`;
5. `build_futures_ribbons.R` on 8 cores, 17 000 draws, ~2.6 h uncontended → `outputs/diagnostics/futures_ribbons_mcmc_20261009_hilda29e_200k.rds`;
6. `diag_mcmc_band_by_chain.R --laplace=none --tag=hilda29e_200k`;
7. `diag_mcmc_drift.R --pooled=… --tag=hilda29e_200k`.
- Each step's stdout goes to that directory (`read.out`, `build.out`, `bychain.out`, `drift.out`).
- ⛔ **Do NOT edit** `read_mcmc_check.R`, `build_futures_ribbons.R`, `diag_mcmc_band_by_chain.R`, `diag_mcmc_drift.R` or `land.sh` until `land.log` says `done`. Bash and Rscript read their scripts as they go.
- This session's waiter on PID 91023 re-invokes only this session. A fresh session should check `kill -0 $(cat ~/ccx_frozen/20261009b_land200k.pid)`, and `land.log`.

**C. Evidence already committed:**
- 100k snapshot `outputs/mcmc_check_20261008j_hilda29e_final/`;
- band `futures_ribbons_mcmc_20261008j_hilda29e_final.rds`;
- `mcmc_band_by_chain_hilda29e_final_20261009.*`, `mcmc_drift_hilda29e_final_20261009.*`;
- the 50k per-chain `mcmc_band_by_chain_hilda29e_snap50k_20261008.*`.

## 3. NEXT

1. **When `land.log` says `done`** (or a STOP; read the rc against the script):
   - commit the snapshot dir, the band, the logs and the landing's `.out` files (the 100k precedent: `ba08df9`);
   - write CHANGELOG 10-09 (c).
2. **Report to Marcus.** Put the three reads side by side: 50k / 100k / 200k, with `hilda33d`'s held stage 1 as the precedent. Report:
   - R-hat / ESS; the band cells' R-hat;
   - **the between-chain range in ppm / °C against the band width** (the deciding units, [[rhat_denominator_forgives]]);
   - whether the band is still widening: late/early AND 100k → 200k width;
   - whether `h_ml` keeps sinking into the floor, and whether its leverage on the futures stays small.
   - ⚠ The 200k band is THINNED ×2 and the 100k one was not. Compare widths and quantiles, not ESS-dependent noise, across them.
   - The expectation (not a measurement) was ESS ×~2.4 and the between-chain range ~1.5× smaller. Read it, do not assume it.
3. **Marcus rules: ship / extend further / hold.** He may also rule on the `h_ml` floor, which is binding in the posterior (his 09-16 b; `CCX_HML_FLOOR_M`, `R/calibrate.R:160`). The futures barely care.
4. **IF "ship":** do the old handoff's §3 item 5, unchanged:
   - lift the `data/` guard for MCMC-provenance draws; write `data/futures_ribbons.rds`; `ccx_ribbons_problems()` must pass;
   - `APP_RIBBONS_HOLD <- NULL`; rewrite `test-futures-ribbons.R` tests 1–6.
   - ⚠ **`RB_LABEL` IS APP COPY once shipped:** `APP_RIBBON_NOTE` renders "Shaded: the 5–95% range of N model runs — a <label>." The current MCMC string ("MCMC posterior draws (supplied), conditional on the fourteen held values") would read badly. Marcus words it.
   - Plus Marcus's copy for card 6 and the global.R "not yet a posterior" clause.
   - ⚠ The GMST band is 0.02–0.09 °C wide (no climate-response name is sampled; `APP_RIBBON_NOTE_TEMP` already says so in words): a presentation question for him.
5. **Still waiting on Marcus's wording** (unchanged): card 4 (`card4_audit_20261008_hilda29e.log`; its two tests fail by design until then); card 8's draft text; the constraint map's caption line; the What-if blurb ("about a third" is now 29 %).

## 4. Non-obvious state

- **Running:**
  - the 4 chains (R PIDs 89223–89226);
  - the landing (bash PID 91023);
  - this session's waiter (re-invokes only this session);
  - NOT ours: the `slr-refresh` MAGICC/Julia job and a VM.
  - ⚠ Check `uptime` before launching anything heavy. Confirm PIDs with `kill -0`, never `pgrep -f`.
- **The frozen worktree is now at `00b1c09`, not `1e00851`.** The chains' `provenance$commit` still says `1e00851` (written at creation). The extension is in `provenance$extended` (commit `00b1c09`), and `read_mcmc_check.R` carries it into the pooled draws as `chain_extended`.
- **Removed this session:** two temporary worktrees of my own (`~/ccx_frozen/suite_20261008_3c754ab`, `~/ccx_frozen/cnt_1f9f904`). Not touched: `~/ccx_frozen/20261008j_mcmc` (in use) and `.claude/worktrees/friendly-einstein-26825b` (the spun-off task's).
- **Untracked, not this session's:** the two `carbotope*.docx`, `outputs/diagnostics/smoke/`, `outputs/mcmc_smoke/`. Leave them.
- **Scratchpad** (lost when this session ends): a copy of the 100k chain files (the committed snapshot is the real copy), the bit-identity test's chains, and the thinned-read test.
- **Memory budgets:** unchanged this session except `laplace_fails_on_fertilisation_ridge.md`, now ~9 KB. `INDEX_ccx_app.md` (14.8 KB) and `INDEX_diag.md` (15.2 KB) are still over the 14 KB soft budget.
- `DESIGN.md` still carries the old −0.36 / 1.8× ocean climate effect (Marcus's spec; flagged, not edited).
- Everything is pushed to `origin/main`, this note's commit included.
