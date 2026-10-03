# HANDOFF 2026-10-02 (i) — objective #15 built, restamped and refitting on the Mac; W4 and the 10-02 comment doc done

**Start here.** Read this note, then CHANGELOG 10-02 (aa)–(gg) (newest first at the top of `CHANGELOG.md`),
then memory `ccx_obj15_lag_built_restamped` (via `INDEX_ccx_var.md`). The plan these steps came from is
`notes/plan_2026-10-02_obj15_lag_iced13c.md`; its W1–W5 and D1–D5 are all DONE or RULED (§2).

## 1. What happened (commits, oldest first)
| commit | CHANGELOG | what |
|---|---|---|
| `fa4636f` | aa | **W1**: the land ENSO lag `lag_enso_land` (DESIGN's `L_MEI`), label `hilda_csl3v0kaidgbe`, a second label gate; absent = bit-identical |
| `0ae4d99` | bb | **#15 code**: W3 ice CO₂ < 1958; W2 Law Dome ice δ¹³C row `d13c_icecore`; W5 `k_w`/`tau_ex` priors cited and moved |
| `f6049e2` | bb | pricing script also covers the hilda31 ratification file |
| `7bd345a` | cc | **#15 priced and restamped**: 6 files; quarantine; test ledger approved; one named red |
| `9a958f7` → `c88c86b` | dd | D3 profile script (`9a958f7` had a line blanked by a mis-aimed sed; fixed, never run broken) |
| `3fc5dca` | dd | **D3 measured**: #15 prefers a lag of ~2.5 months (+12.1 vs 0); 5 months is +1.7 |
| `ea2911f` | ee | **the refit launched on the Mac** (both arms, from frozen worktrees at `3fc5dca`) |
| `e47e9c9` | ff | **W4**: the gate repairs (5, 6, 7, 11, P7, ledger row D) |
| `32475d4` | gg | Marcus's `carbotopecomments.10.2.26.docx` items; the W4 scorecard record |

## 2. Rulings this session (verbatim labels; CHANGELOG carries each in full)
- D4: σ "Stated ⊕ 0.05‰"; end "Before 1977"; anchor "Keep from 1750". W5: `k_w` "1446, log-sd 0.2"; `tau_ex`
  "Mass basis 0.8 / 0.26". New doc: "After the #15 build".
- Test ledger for #15: "Approve all"; constraint map: "After #15 adoption" (a NAMED RED until then).
- D3: "Fit it free". D5: "Mac" (my verdict was Torch). "Keep going here".
- W4: gate 5 "Gate on LOO spreads"; gate 6 "Two-sided, bootstrap se"; gate 11 "Capture in ccx_loglik";
  the gate-bounds fixture "Approve"; the LUC-panel re-pin "Approve".
- ⚠ **Still his call, never asked as a question:** the label NAME `hilda_csl3v0kaidgbe` (said in CHANGELOG aa),
  and the interpolation choice (a backward-difference cubic Hermite, NOT the plan's Catmull-Rom, which is
  acausal for lags under one month — measured; CHANGELOG aa, "DEVIATION 1").

## 3. THE REFIT — running at handoff
- **Chain:** `~/ccx_frozen/20261002ee_obj15_launch.sh` under `nohup`, PID in `~/ccx_frozen/20261002ee_obj15_launch.pid`,
  status lines in `~/ccx_frozen/20261002ee_obj15_launch.out` ("arm … start/end", then "ALL ARMS DONE").
  Launched 21:29 EDT 10-02. Lag arm first, then the control.
- **Trees** (git worktrees at `3fc5dca`, `nuclear14c` copied in, port targets regenerated, preflight 24/24):
  `~/ccx_frozen/20261002ee_obj15_lag` (`hilda_csl3v0kaidgbe`, 34 free) and `~/ccx_frozen/20261002ee_obj15_ctl`
  (`hilda_csl3v0kaidgb`, 33 free). 24 starts each, 8 at a time, WALL 300 min, 3 restarts × 6 cycles × 6000.
- **Outdirs** (inside each tree): `calibration/output/multistart_20261002ee_<label>_seasml1_pin_ent_seas_amp_SH=0_w_eq=27_gamma_eq=1_pump_export=9.08_w_vent=0_gamma_vent=0_w_thc=0_gamma_enso_ocn_NH=0_gamma_enso_ocn_SH=0_sd1.0452_sdby_npp_tsens=0.0291`.
- **Logs:** each tree's `logs/wave_20261002ee.log`, `logs/ccx_multistart_mac_20261002ee_<id>.out`, `…_exit.txt`.
- **Check it with `ps`, not `pgrep "Rscript …"`:** Rscript re-execs as `…/exec/R … --file=calibration/run_dispersed_multistart.R`.
  `ps -Ao etime,command | grep "[e]xec/R.*run_dispersed_multistart" | wc -l` → 8 while a round runs.
- **Rate at launch:** 0.32–0.51 s/eval (8 running). At 2.4 h the near-incumbent starts read logpost −1183 to −1190
  (lag arm; the lag's logit Jacobian is IN that number — compare arms on LIKELIHOOD).
- **Expected:** ~9 h per arm if it behaves like #14 ⇒ both done around mid-day 10-03; worst case ~06:00 10-04.

## 4. When it lands — the steps, per arm
1. Copy the outdir from the frozen tree into the repo's `calibration/output/`.
2. `CCX_MS_OUTDIR=<that dir> Rscript calibration/collect_dispersed_multistart.R` (env var, not `--outdir`).
3. `Rscript calibration/promote_multistart_mode.R …` (GATES 1–5), then `Rscript calibration/recompute_hessian.R <mode> --update`.
4. **Read the refit** in a committed driver, like `diag_obj14_refit_read.R`:
   - basin agreement across the 24 starts;
   - the fitted lag and its Hessian sd (D3's conditional answer was ~2.5 months);
   - the two arms on LIKELIHOOD over the same rows. The lag arm adds one prior; never compare stored logposts across labels;
   - whether `k_w` moves toward Naegler's 1446 (the ice δ¹³C row's hint, CHANGELOG cc);
   - the gate-5 sub-checks.
5. **Score** with `calibration/diag_whole_model_scorecard.R` (the W4 gates). The pre-refit baseline is
   `outputs/diagnostics/whole_model_scorecard_20261002w4.log`.
6. **Adoption is Marcus's ruling.** If adopted:
   - register the mode in `R/paths.R`; point the app at it (`APP_RELEASE_MODE`, `test-app-version`);
   - re-run `calibration/diag_enso_growth_fit.R` (the What-if question that started this);
   - rebuild `data/constraint_map.rds` with `calibration/diag_constraint_map.R`, which CLEARS the named red;
   - run the suite on a frozen copy.

## 5. Non-obvious state
- **The named red:** `test-constraint-map` 6, which waits for the adoption. Every suite run since `7bd345a` shows exactly
  1 failure; anything more is new.
- **Frozen-copy suite recipe** (or it under-reports):
  - copy `outputs/` and ALL of `calibration/output/` — three tests read multistart dirs;
  - plus `data-raw/downloads/nuclear14c` and `glodap_c13c14_subset.csv`;
  - pin BLAS.
  - Last counts: 5999 / 1 / 4 / 0 at `e47e9c9`, 21 min under the refit's load (13 min idle).
- **The app preview** (`ccx-app`, localhost:7788) is RUNNING on the current tree (started for the 10-02 doc's
  checks).
- **Untracked, Marcus's:** `carbotopecomment.9.26.26.docx` and `carbotopecomments.10.2.26.docx`. Both are done;
  never commit or edit them. Word had the second one open.
- **Untracked, deliberately:** `outputs/mcmc_smoke/`, `outputs/diagnostics/smoke/`.
- **Two stale git worktrees** sit under `.claude/worktrees/` (`compassionate-leavitt…`, `youthful-blackburn…`), from earlier
  sessions. They are not this work; leave them to Marcus.
- **Memory keyspace:** this session was LAUNCHED in `CarbonCycleEmulator/` and loaded the shared root `MEMORY.md`
  through the 09-25 symlink — the first direct observation that the harness follows it (memory
  `memory_keyspace_follows_launch_cwd`). Neither `CLAUDE.md` was changed; that wording is Marcus's.
- **Mutation harness:** it lived in this session's scratchpad (`mut/mutate.py`), not the repo. The mutation lists
  and their outcomes are in CHANGELOG aa, bb and ff.
