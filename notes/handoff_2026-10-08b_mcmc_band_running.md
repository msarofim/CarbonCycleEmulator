# HANDOFF 2026-10-08 (b) — the MCMC band is RUNNING at `hilda29e`; card 8 built; the H2 stake re-measured; NEXT: read the chains at 100k, then Marcus rules on shipping

> **SUPERSEDED 2026-10-09 by `notes/handoff_2026-10-09_mcmc_200k_running.md`** (the 50k and 100k reads done; Marcus ruled "Extend to 200k", "Thin ×2 within chain"; the chains are extending and the 200k landing is armed).

**Supersedes** `notes/handoff_2026-10-08_hilda29e_adopted.md`. Its §3 items 1–2 are done except card 4's COPY; its §3.3 / §4 / §5 lists still apply where not listed here.
Written on Marcus's request ("Yes, write the handoff note"), 2026-10-08 ~21:50 EDT, while the chains and a band build run.

**Start here.**
1. CHANGELOG 2026-10-08 (g)–(k), newest first.
2. Memory, shared store:
   - `laplace_fails_on_fertilisation_ridge`: the Gaussian verdict at `hilda29e` and the MCMC launch;
   - `ccx_h2_tested_and_priced` and `ccx_ocean_climate_effect_vs_gcb`: H2 is one issue with the ocean climate effect;
   - `skip_guard_silent_on_adoption`: a gate a comment claims but no test implements;
   - `ccx_hilda29e_adopted`.
3. `~/.claude/CLAUDE.md` and this repo's `CLAUDE.md`.

## 1. What was done this session (rulings verbatim)

| Ruling (Marcus) | Outcome |
|---|---|
| "Read handoff … and continue work" | **Card 4 audited** (`calibration/diag_card4_audit.R`). THREE typed claims are false at `hilda29e`: the lag 2.5 (runs 5.93 ± 1.21); "a little below" (w 16.79 is inside 14–25); the growth-peak timing (the model now peaks at 5 mo = the record). "More El Niño-driven" is ESTIMATOR-DEPENDENT. 60 % → 66 % and 1.5 → 1.0 ppm are wording calls. "A little below" was NEVER gated, although `review.R` said so. |
| "Both, now (Recommended)" | Card 4's lag test reads the lag the canonical RUNS (pinned → `CCX_MODE_CANONICAL_MODULE_CHECK`'s Laplace, md5-gated), and the missing relation test exists. **Both FAIL until card 4's copy changes** (by design). |
| "Main fit only (Recommended)" | Constraint map rebuilt at `hilda29e` (26 streams × 29 names; GATE MODULE cross-checks the cut flag against the likelihood) plus a computed caption line (Claude's draft). |
| "Remove all three [frozen trees]" | Two were removed (the 9e22e3b tree was already gone); their results were verified landed first. |
| "Evaluate if the posterior bands are feasible…" | **NOT feasible as ruled.** The main fit's Laplace fails the importance check: ESS 3.3/1000, Pareto k̂ 0.90 (reliable < 0.667). A curvature-matched Gaussian fails too (ESS 14.8, k̂ 1.06). Tooling: `R/importance.R` (validated), `calibration/diag_cut_laplace_is.R`. **H2 = the ocean climate effect:** detrending removed a trend-borne ENSO-limb credit (+0.094 → +0.040) and the thermal part did not move. H2 at `hilda29e`: 1.81 ± 0.40× GCB per K, 27 yr early. |
| **"MCMC band; go ahead with the card and futures re-measurement."** | See §2. |

## 2. Where things stand NOW

**A. The MCMC band. RUNNING; nothing shipped; `APP_RIBBONS_HOLD` still set.**
- **4 chains of `calibration/run_mcmc_check.R`**:
  - frozen worktree `~/ccx_frozen/20261008j_mcmc` at `1e00851`; launched 16:42 EDT by `~/ccx_frozen/20261008j_mcmc_launch.sh`;
  - n 1e5, adaptation frozen at 3e4, t0 1000, thin 20, checkpoint 500 (`hilda33d`'s production settings);
  - **R PIDs 41076–41079** (`~/ccx_frozen/20261008j_mcmc.pids`), each under `caffeinate -i -s`;
  - logs `~/ccx_frozen/20261008j_mcmc_chain{1..4}.out`; chain files in `~/ccx_frozen/20261008j_mcmc/outputs/mcmc_check_20261008j_hilda29e/chain_{1..4}.rds`.
  - At 21:50 they were at 58–60k. ~0.39 s/iteration now; it was ~0.6 while an unrelated Jupyter kernel (`MAGICC/slr-refresh/notebooks`) ran 16:48–~20:00. **Expected done ~02:00–02:30 EDT 10-09.**
  - Exactly resumable: re-running the launch script continues each chain. Do NOT add `--commit` (it mislabels a worktree as "not a checkout").
- **What it samples:** the 29 main-fit names with the 14 held values held, the interannual module among them. ⇒ the band is CONDITIONAL ON STAGE 1 AT ITS MODE. The module's move shifted the 2300 futures by ≤ 0.6 ppm (10-07 h).
- **The 50k snapshot read** (`outputs/mcmc_check_20261008j_hilda29e_snap50k/`, committed `641732c`; window (30000, 51000], 1050 kept/chain):
  - **NOT converged by Vehtari et al. (2021)'s reference:** R-hat max 1.13 (`ndep_ret`), `beta_max` 1.08, all 30 quantities > 1.01; min bulk ESS 21, min tail ESS 37.
  - The log-posterior has been stable at the Gaussian level (−1181) since ~5k.
  - Post-adaptation acceptance is LOW, 0.056–0.075 (optimal ~0.23 in 29-D): slow mixing.
  - `h_ml`: posterior median 57.4 m (90 % 47.5–69.9) against the mode's 64.6. The mode is at ~80th percentile; 5 % of draws are within 5 m of the 42.5 floor; the chains agree (54.5–59.8). The Laplace understates its spread ~4×; along the fertilization ridge it OVERstates it.
- **The band from the 50k snapshot is BUILDING** (`build_futures_ribbons.R --draws=…snap50k/pooled_u.rds --cores=6 --out=outputs/diagnostics/futures_ribbons_mcmc_20261008j_hilda29e_snap50k.rds`):
  - R PID 64314, started ~21:07, expected ~45–60 min;
  - stdout `/private/tmp/claude-501/…/scratchpad/ribbons50k.out` (scratch: lost if the session ends; its own log is `outputs/diagnostics/futures_ribbons_mcmc_20261008j_hilda29e_snap50k_<date>.log`, untracked until committed).

**B. Card 8, the ocean's climate effect: BUILT, renders, tests pass** (`5696698`, `fd6b122`, `3b19610`).
- `data/ocean_climate_card.rds` comes from `calibration/build_ocean_climate_card.R`, which collects three md5-gated diagnostics.
- Class `response`, a new gloss. **The card TEXT and the gloss are CLAUDE'S DRAFT, FOR MARCUS'S WORDING.**
- `test-ocean-climate-card.R` 25 / 0. It FAILS at an adoption that does not rebuild the product.

**C. The H2 futures stake at `hilda29e`** (`h2_futures_stake_20261008_hilda29e.*`):
- the GCB-sized f is 0.494, now DERIVED per mode; `hilda33p`'s typed f were mis-sized here;
- CO₂ in 2300: SSP5-8.5 **−31.3** ppm (−24.7 to −38.0), vvH −24.5, vvM −14.4. `hilda33p` was −23.6 / −18.5 / −11.0.

## 3. NEXT

1. **When the chains finish** (all four logs say `COMPLETE`, or `iter 100000/100000`):
   - Snapshot the chain files into the repo, e.g. `outputs/mcmc_check_20261008j_hilda29e_final/`. Read them there, never the live dir.
   - Then `Rscript calibration/read_mcmc_check.R --dir=<snapshot>`; window (30000, 100000], ~3500 kept/chain. Use `--drop=` only if the log-posterior blocks show drift.
   - It writes `pooled_u.rds`.
2. **Build the candidate band:**
   - `Rscript calibration/build_futures_ribbons.R --draws=<snapshot>/pooled_u.rds --cores=8 --out=outputs/diagnostics/futures_ribbons_mcmc_20261008j_hilda29e_final.rds`. 14 000 draws is ~2.5 h on 8 cores; thinning within each chain is an option, but preserve the chain-by-chain order and the provenance.
   - Then `Rscript calibration/diag_mcmc_band_by_chain.R --ribbons=<that> --draws=<pooled_u> --tag=hilda29e_final`. Its `--laplace` default is `hilda33d`'s held band, not like-for-like; ignore that column or point it elsewhere.
3. **Do the same per-chain test on the 50k snapshot band first** (§2.A, when PID 64314 finishes): `--tag=hilda29e_snap50k`.
4. **Report to Marcus. He RULES whether a band ships** (`read_mcmc_check.R` header; handoff 10-01e). Report:
   - R-hat / ESS;
   - the band cells' R-hat;
   - the between-chain spread in ppm / °C against the band width (`hilda33d`'s precedent: ≤ 3.4 ppm, 15–30 % of width, and Marcus held);
   - whether the band is still widening (50k vs 100k).
   - Options if unconverged: longer chains (resumable: raise `--n`; NOT a fresh run); better mixing (the frozen proposal's acceptance is 0.06–0.075); or hold.
5. **IF Marcus rules "ship":**
   - lift `build_futures_ribbons.R`'s "--draws output must not land in data/" guard, for draws carrying MCMC provenance;
   - write `data/futures_ribbons.rds`; check `ccx_ribbons_problems()` (`R/paths.R`) passes;
   - `APP_RIBBONS_HOLD <- NULL` (`app/global.R`);
   - rewrite `test-futures-ribbons.R` test 1 (it fails by design when the hold lifts) and tests 2–6 (pinned to the `hilda33d` evidence);
   - `RB_LABEL` (its word list stops at twelve; there are 14 held values; "held" is now "conditional on the El Niño module");
   - **Marcus's copy:** card 6 ("There are no uncertainty bands, anywhere"; facts in `notes/card6_facts_2026-10-02.md`) and the global.R clause "A single best fit, not yet a posterior" (lines ~334–339).
6. **Still waiting on Marcus's wording:** card 4 (numbers: `outputs/diagnostics/card4_audit_20261008_hilda29e.log`); card 8's draft text; the constraint map's caption line; the What-if blurb ("about a third" is now 29 %). Plus the handoff 10-08 §3.3 list and pre-launch items.

## 4. Non-obvious state

- **Running processes:**
  - the 4 chains (R PIDs 41076–41079);
  - the band build (PID 64314);
  - a background waiter in the old session (it only re-invokes that session).
  - ⚠ Before launching anything heavy, check `uptime`. A fresh session should confirm the chain PIDs are alive with `kill -0`, NOT `pgrep -f` (it self-matches).
- **CHANGELOG (k)** covers `641732c` (the 50k snapshot read) and `551928e`. The latter is the spun-off task's fix: `diag_growth_residual_years.R` builds the structure's forcing, and it landed on `main` from that task's own session.
- **The suite at `1f9f904`:** 7037 passed / 2 failed (card 4's two, by design) / 0 errors / 3 standing skips. Not re-run since card 8 and the importance module. The app-facing files were run individually: card 8 25/0, review-cards 48/0, review-copy 41/0, plot-text-fits 102/0, importance 17/0.
- **Untracked:** `outputs/diagnostics/futures_ribbons_mcmc_20261008j_hilda29e_snap50k_20261008.log` (the band build's own log, in progress). Not this session's: the two `carbotope*.docx` files, `outputs/diagnostics/smoke/`, `outputs/mcmc_smoke/`. Leave them.
- **Frozen trees:** `~/ccx_frozen/20261008j_mcmc` (in use). Removable once the chains finish and their files are snapshotted into the repo, but ask Marcus. Loose launcher scripts from earlier waves are still in `~/ccx_frozen/` (copies are in the repo).
- **Memory budgets:** `INDEX_ccx_app.md` 14.8 KB and `INDEX_diag.md` 15.2 KB, both over the 14 KB soft budget and under the 18 KB hard one.
- **`DESIGN.md` still carries the old −0.36 / 1.8× ocean climate effect.** It is Marcus's spec; flagged, not edited.
- **The app is not public.** `APP_RIBBONS_HOLD` stays until Marcus rules.
