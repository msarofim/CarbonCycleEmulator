# HANDOFF 2026-10-03 — the objective-#15 refit: the lag arm is nearly done, the control arm is next

**Supersedes** `notes/handoff_2026-10-02i_obj15_refit_running.md`. This note is self-contained, and it adds the
refit's state as of 07:43 EDT 10-03.

**Start here.**
1. Read this note.
2. Then CHANGELOG 10-02 (aa)–(hh), newest at the top of `CHANGELOG.md`.
3. Then memory `ccx_obj15_lag_built_restamped`, reached through `INDEX_ccx_var.md`.

The plan behind the work is `notes/plan_2026-10-02_obj15_lag_iced13c.md`. All of its W1–W5 and D1–D5 are done or ruled.

## 1. What we are doing
- Marcus asked why switching ENSO off did not hurt the What-if fit. The model's land ENSO response was ~5 months early, and DESIGN's fitted lag `L_MEI` had never been built (10-02 x).
- He ruled "Do it right": build the lag, fold in the other never-built DESIGN items, and refit.
- Built and committed on 10-02:
  - **W1**: the lag `lag_enso_land`, fitted only under the label `hilda_csl3v0kaidgbe`.
  - **Objective #15**: the ice-core CO₂ row cut to before 1958; the Law Dome ice δ¹³C row; the `k_w` and `tau_ex` priors cited and moved.
  - The restamp of all six mode files.
  - **W4**: the gate repairs.
  - Marcus's 10-02 comment doc.
- **What is left is the refit itself, reading it, and the adoption ruling.**

## 2. Decisions and their reasons (verbatim labels; CHANGELOG has each in full)
- **D4, the ice δ¹³C row:**
  - σ "Stated ⊕ 0.05‰": the SPO station row's own representation floor, since Law Dome reads the same SH box.
  - End "Before 1977": SPO's δ¹³C record starts in 1977, and the CO₂ cut follows the same logic.
  - Start "Keep from 1750": the CO₂ row's rule.
- **W5, the priors:**
  - `k_w` "1446, log-sd 0.2": Naegler 2009, 16.5 ± 3.2 cm/h.
  - `tau_ex` "Mass basis 0.8 / 0.26": the boxes are whole hemispheric masses, so the prior is on that basis. It is model-derived, and the constant says so.
- **D1** "Every version, as objective #15" (restamped). **D2** "Yes, run the control". **D3** "Fit it free" (the conditional profile preferred ~2.5 months). **D5** "Mac"; my verdict was Torch.
- **The restamp's test ledger:** "Approve all". **The constraint map:** "After #15 adoption", so it stays a NAMED RED until then.
- **W4:**
  - gate 5 "Gate on LOO spreads", so gate 5 now FAILS at every mode;
  - gate 6 "Two-sided, bootstrap se";
  - gate 11 "Capture in ccx_loglik".
  - Two test changes approved: the `test-gate-bounds` fixture and the LUC-panel re-pin.
- ⚠ **NOT yet ruled; raise these with Marcus:**
  - the label NAME `hilda_csl3v0kaidgbe` is my placeholder;
  - the interpolation deviation: a backward-difference cubic Hermite instead of the plan's Catmull-Rom. Catmull-Rom is acausal for lags under one month (measured; CHANGELOG aa).

## 3. Files and commits (all pushed; HEAD `b2d0934` before this note)
- **Code:**
  - `R/model.R`: the lag helpers and the land term.
  - `R/forcing.R`, `R/cpp.R`, `src/ccx_core.cpp`: the `land_enso` series reaching both cores.
  - `R/spinup.R`
  - `R/calibrate.R`: `CCX_PARAM_GATES` and the new label.
  - `R/likelihood.R`: the #15 rows, `ccx_with_obj14_ice()`, and `ccx_loglik(residuals =)`.
  - `R/constants.R`: the four prior constants.
  - `calibration/lib_design_gates.R`: W4.
  - `calibration/diag_whole_model_scorecard.R`
  - the app: `global.R`, `ui.R`, `server.R`, `R/params_meta.R`; and `R/mechanisms.R`.
- **New tests:** `test-enso-lag.R`, `test-obj15.R`, `test-gates-w4.R`.
- **New drivers:** `diag_ice_d13c_sigma.R`, `diag_obj15_price.R`, `diag_lag_profile_obj15.R`.
- **Outputs:**
  - `outputs/diagnostics/{ice_d13c_sigma,obj15_price,restamp_obj15,lag_profile_obj15}_20261002.*`
  - `outputs/diagnostics/whole_model_scorecard_20261002w4*`: the pre-refit baseline under #15 with the repaired gates.
- **Quarantine:** `calibration/output/quarantine/20261002_obj15_restamp/`, holding the six pre-#15 mode files with a README.

## 4. THE REFIT — state at 07:43 EDT 10-03
- **The chain:** `~/ccx_frozen/20261002ee_obj15_launch.sh` under `nohup`, launched 21:29 10-02.
  - PID file: `~/ccx_frozen/20261002ee_obj15_launch.pid`. Status lines: `~/ccx_frozen/20261002ee_obj15_launch.out`.
  - It runs the lag arm, then the control arm, then prints "ALL ARMS DONE".
- **The lag arm** (`~/ccx_frozen/20261002ee_obj15_lag`, `hilda_csl3v0kaidgbe`, 34 free):
  - **22 of 24 starts finished, every exit 0.** ids 21 and 23 were still running, in their wall budget's second cycle.
  - ⚠ **PRELIMINARY, read straight from the start files.** Not yet collected or promoted, so the collector's verdict decides:
    - the best logpost is **−1182.99**, from 3 starts (004, 016, and 023 while still running);
    - 17 more starts sit within 0.16 of it (−1183.15);
    - outliers: 008 at −1183.17, 006 at −1185.33, 021 at −1185.8 while running, and **017 at −1319.64**.
  - **At the best starts:**
    - **lag 2.644 months.** All the top starts agree to 3 decimals. D3's conditional profile said ~2.5.
    - **`k_w` 1894–1903 m/yr.** That is barely below hilda33d's 1921 and NOT toward Naegler's 1446. The hint from CHANGELOG cc did not pan out.
    - **`tau_ex` 0.882–0.885 yr.**
    - **Land ENSO amplitudes:** NH 0.536 and SH 0.51, up from 0.45 and 0.33.
  - ⚠ The lag arm's logpost includes the lag's prior and logit Jacobian. **Compare the arms on LIKELIHOOD over the same rows, never on stored logposts.**
- **The control arm** (`~/ccx_frozen/20261002ee_obj15_ctl`, `hilda_csl3v0kaidgb`, 33 free) **had not started.** The chain starts it automatically when the lag arm's last two tasks finish.
  - The lag arm had run ~10.2 h with 2 tasks left. At that pace (8 at a time) expect the control arm this evening (10-03).
- **How to check:**
  - Task count: `ps -Ao etime,command | grep "[e]xec/R.*run_dispersed_multistart" | wc -l`.
  - Exits: each tree's `logs/ccx_multistart_mac_20261002ee_exit.txt`.
  - Per-task logs: `logs/ccx_multistart_mac_20261002ee_<id>.out`.
  - ⛔ **Do NOT use `pgrep -f "Rscript …"`.** Rscript re-execs as `…/exec/R --file=…`, so it never matches; and a wait-loop's own command line contains the pattern.
- ⛔ **Never edit files inside `~/ccx_frozen/20261002ee_obj15_*` while tasks run** (never_edit_a_running_script). Copy the outputs out instead.

## 5. Next steps, in order
1. **Lag arm, once its 24 exits are recorded:**
   - copy its outdir into the repo's `calibration/output/`;
   - `CCX_MS_OUTDIR=<dir> Rscript calibration/collect_dispersed_multistart.R` (an env var, not `--outdir`);
   - then `promote_multistart_mode.R` (GATES 1–5);
   - then `recompute_hessian.R <mode> --update`.
   - The outdir name: `multistart_20261002ee_hilda_csl3v0kaidgbe_seasml1_pin_ent_seas_amp_SH=0_w_eq=27_gamma_eq=1_pump_export=9.08_w_vent=0_gamma_vent=0_w_thc=0_gamma_enso_ocn_NH=0_gamma_enso_ocn_SH=0_sd1.0452_sdby_npp_tsens=0.0291`.
2. **The control arm, the same way, when the chain prints "ALL ARMS DONE".**
3. **Read the refit in a committed driver**, on the model of `calibration/diag_obj14_refit_read.R`. Read:
   - how well the starts agree on one basin;
   - the lag and its Hessian sd;
   - the two arms on LIKELIHOOD, and the lag's AIC worth (one parameter);
   - which rows the lag buys;
   - why `k_w` stayed high;
   - and 017's −1319 start: is it a stuck start or a real second basin?
4. **Score both arms** with `calibration/diag_whole_model_scorecard.R`. Compare with `outputs/diagnostics/whole_model_scorecard_20261002w4.log`; gate 5 is expected to stay FAIL.
5. **Re-run `calibration/diag_enso_growth_fit.R` on the lag arm's mode.** This is the What-if question that started all of this; at hilda33d the RMS gap vs ENSO-off was ~1 %.
6. **Bring Marcus the adoption ruling, with numbers.** If he adopts:
   - register the mode in `R/paths.R`;
   - point the app at it (`APP_RELEASE_MODE`, `test-app-version`);
   - rebuild `data/constraint_map.rds` (`calibration/diag_constraint_map.R`), which CLEARS the named red;
   - run the suite on a frozen copy (§6);
   - update the memory.
7. **Also raise:** the label name, and the interpolation deviation (§2).

## 6. Non-obvious state
- **The named red is `test-constraint-map` 6.** Every suite run since `7bd345a` shows exactly 1 failure; anything more is NEW.
  The last counts were **5999 / 1 / 4 / 0** at `e47e9c9`.
- **The frozen-copy suite recipe**, or it under-reports:
  - copy `outputs/` and ALL of `calibration/output/`, because three tests read multistart dirs;
  - plus `data-raw/downloads/nuclear14c` and `data-raw/downloads/glodap_c13c14_subset.csv`;
  - pin BLAS to one thread;
  - run `tests/testthat` with a counting reporter.
  - It takes 13 min idle, 21 min while the refit runs.
- **The app preview `ccx-app`** answers on localhost:7788 (HTTP 200 at 07:43), on the tree as of `32475d4`. Marcus's 10-02 doc items were verified there.
- **Untracked files that are Marcus's** — never commit or edit them: `carbotopecomment.9.26.26.docx` and `carbotopecomments.10.2.26.docx`. Both are worked through.
- **Untracked deliberately:** `outputs/mcmc_smoke/` and `outputs/diagnostics/smoke/`.
- **Two stale git worktrees** sit under `.claude/worktrees/` (`compassionate-leavitt…`, `youthful-blackburn…`), from earlier sessions. They are Marcus's to remove.
- **The memory keyspace:** the 10-02 session was LAUNCHED in `CarbonCycleEmulator/` and still loaded the shared root `MEMORY.md` through the symlink. That is the first direct observation, recorded in memory `memory_keyspace_follows_launch_cwd`. Neither `CLAUDE.md` was edited.
- **The mutation harness** lived in the 10-02 session's scratchpad (`mut/mutate.py`), not the repo. Its mutation lists and outcomes are in CHANGELOG aa, bb and ff.
- **A lesson filed in memory** (`multiline_shell_keeps_going`): a failed line in a multi-line shell call does NOT stop the next line. A commit on the next line still ran (`9a958f7`).
