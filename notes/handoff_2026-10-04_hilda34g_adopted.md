# HANDOFF 2026-10-04 — `hilda34g` is the canonical; the objective-#15 arc is closed

**Supersedes** `notes/handoff_2026-10-03_obj15_refit.md`. Self-contained.

**Start here.**
1. Read this note.
2. Then CHANGELOG 2026-10-03 (b)–(i) and 2026-10-04 (a), newest at the top of `CHANGELOG.md`.
3. Then memory `ccx_hilda34g_adopted` (routed from the root `MEMORY.md` and `INDEX_ccx.md`'s live state), and
   `ccx_kw_hemispheric_balance`.

⚠ Launch sessions from `FaIRtoFrEDI/` and move here with `change_directory` (this repo's `CLAUDE.md`).

## 1. What was done (10-03 → 10-04)
- **The question that started it** (Marcus 10-02 x): why does switching ENSO off not hurt the app's What-if fit?
  The model's land ENSO response came ~5 months early, and DESIGN's fitted lag `L_MEI` had never been built.
- **The refit** ran on the Mac: the lag arm `hilda_csl3v0kaidgbe` (34 free) and the lag-0 control `hilda_csl3v0kaidgb`
  (33 free), 24 dispersed starts each, on objective #15. Both arms are landed, read, and committed.
- **Adopted as `hilda34g`** on Marcus's rulings, then the ledger applied. **The full suite at `e2f611b` is clean:
  6030 passed, 0 failed, 3 skipped (the standing three), 0 errors. No named red remains.**

| | hilda33d (previous canonical) | the control (not registered) | **hilda34g** |
|---|---|---|---|
| likelihood, the 27 rows of #15 | −1170.581 | −1158.168 | **−1143.251** |
| `lag_enso_land` (months) | 0 | 0 | **2.64 ± 0.39** |
| What-if readout (+ = ENSO off closer) | +0.92 % | +0.89 % | **−11.0 %** |
| growth peak after Niño 3.4 (obs +5) | −2 months | −2 | **+1** |
| gate V (z) | −4.52 | −4.34 | −4.60 |
| SSP5-8.5 CO₂ 2300 (ppm) | 1491.6 | 1476.2 | 1448.6 |

- **The lag earns its parameter:** lag − control = +14.92 on likelihood at one name, ΔAIC −27.8. Every What-if gain
  is the lag's. ⚠ Gate V gets slightly worse: the lag fixes ENSO's TIMING, not the missing interannual AMPLITUDE.
- **The futures move is NOT the lag's own** (its direct effect on 2300 CO₂ is < 0.01 ppm, power-checked). The land
  re-arranged around it: `npp_tsens` −0.0079 → +0.0089 /K (−91 ppm at SSP5-8.5 2300) against `beta_max`
  2.23 → 1.83 (+71). The reading that the negative greening term had been patching the too-early ENSO response is
  **UNTESTED**.
- **`k_w` stays ~1900 m/yr** (Naegler 2009: 1446) at all three vectors. One global scalar balances the NH-box rows
  (+63 per +10 %) against the SH-box rows (−62); the new ice-core δ¹³C row is ~15× weaker
  ⇒ memory `ccx_kw_hemispheric_balance`.
- **Start 017** (lag arm, −1319.6, out of time twice) was STUCK on a non-smooth edge, not a second basin. There,
  0.1-sd steps in `kz` / `kz_deep_frac` move `co2_seasonal_SPO` by ~−250, and an `h_ml` step sends
  `d13c_seasonal_SPO` to −2e37 (CHANGELOG 10-03 e).

## 2. Rulings (Marcus, verbatim labels; each in the CHANGELOG where it was applied)
- 10-03 (h): "Adopt the lag arm (Recommended)"; "Keep label; mode hilda34g (Recommended)"; "Keep backward-difference
  Hermite (Recommended)" (the interpolation deviation from the plan's Catmull-Rom, 10-02 aa); "\"about 40 %\"
  (Recommended)" (the ENSO blurb).
- 10-03 (i): "Move v1.0 to hilda34g (Recommended)" (`APP_RELEASE_MODE`); "Keep 'about 1.4'; about = within 0.1
  (Recommended)" (the pulse box, `APP_PULSE_PER1000_ABOUT_TOL`); "Approve all (Recommended)" (the test ledger).
- 10-04 (a): "Remove the frozen refit trees and write the handoff note" (done; this note).

## 3. Files (all committed and pushed; HEAD at the 10-04 (a) commit)
- **Mode:** `calibration/output/refit_20261003_hilda34g_obj15_hilda_csl3v0kaidgbe/` (renamed at adoption from
  `refit_20261003_obj15_…`; the 10-03 (b)–(g) outputs record the old path). The control:
  `calibration/output/refit_20261003_obj15_hilda_csl3v0kaidgb/`.
- **The waves**, copied byte-identical with logs, preflight, port targets, `RUN_PROVENANCE.txt`:
  `calibration/output/multistart_20261002ee_{hilda_csl3v0kaidgbe,hilda_csl3v0kaidgb}_…_sdby_npp_tsens=0.0291/`;
  017's resume: `calibration/output/resume017_20261003_…/`.
- **New drivers:** `calibration/diag_obj15_refit_read.R` (the read; section 8 decomposes the futures by group swap) and
  `calibration/diag_app_wobble_shares.R` (the What-if blurb's shares on the app's own estimator, gated to reproduce
  10-02 w at hilda33d).
- **Changed:**
  - `R/paths.R`: the registry, and `ccx_ribbons_problems()` now checks the name against its `mode` argument.
  - `R/mechanisms.R`: the blurb.
  - `app/global.R`: the release mode and the pulse constants.
  - `calibration/diag_whole_model_scorecard.R`: `CCX_SC_EXTRA_MODE` takes `name=path[,…]`; P7 at extra arms.
  - `calibration/diag_enso_growth_fit.R`: the output stem carries the mode.
  - `calibration/diag_constraint_map.R`: `lag_enso_land` in "ENSO response"; a new family "δ¹³C in ice cores";
    `CM_DATE` 20261003h.
  - `calibration/run_dispersed_multistart.R`: the reference label no longer types "objective #12".
  - README, `app/DEPLOY.md`, DESIGN (`L_MEI` fitted), `make_bundle.sh`; eight test files (the approved ledger).
- **Outputs** (`outputs/diagnostics/`): `obj15_refit_read_20261003.*` (+ `_INTERIM`),
  `whole_model_scorecard_20261003_hilda33d_obj15{lag,arms}.*`, `enso_growth_fit_20261003_cand15{lag,ctl}.*`,
  `app_wobble_shares_20261003_{hilda33d,cand15lag,cand15ctl}.*`, `pulse_vs_tcre_20261003.*`,
  `constraint_map_20261003h.log`, the suite logs `suite_20261003_{cf7cb6c_all,cf7cb6c_preview_cand15lag,115dc22_adoption,e2f611b_all}.log`,
  and the scratch-worktree diffs (`*_worktree.diff`) behind every "(+uncommitted)" stamp.
- **Data:** `data/constraint_map.rds` rebuilt at hilda34g.

## 4. Open items, roughly in order (none is a blocker; each is Marcus's to prioritise)
1. **The background task "Diagnose the SPO seasonal-row cliff near start 017"** runs in a separate session (worktree
   `.claude/worktrees/pensive-burnell-a9bf40`). It was told not to change any stored logpost without a priced
   objective change and Marcus's ruling. **Read its result and merge its branch; it may touch `CHANGELOG.md`'s top.**
2. **The lag vs the atmosphere's timing.** The rows that set L (GCB's DGVM-based land sink, the SPO seasonal rows)
   prefer ~2.6 months. The What-if fit and the observed growth timing want ~5 (T7: +15.4 % at a further 3 months). The
   growth-rate row was declined 09-26, to be re-proposed only "with a NEW reason"; this may be one. Not raised yet.
3. **The untested greening reading** (§1). A test: refit or profile the lag-0 control with `npp_tsens` constrained
   positive, or score hilda34g with the lag set to 0 and `npp_tsens` re-optimised conditionally.
4. **`k_w`'s marginal price at 1446**: a re-fit at fixed `k_w` (offered, not run). The conditional price is 1784
   log-units, the Laplace one ~47.
5. **The "δ¹³C in ice cores" family label** in the app's "What pins down what?" tab is MY choice, parallel to
   "CO₂ in ice cores". Folding it into "δ¹³C level & gradient" is one line in `diag_constraint_map.R`, plus a rebuild.
6. **An assessment / freeze record for hilda34g**, if wanted (10-01 had `notes/assessment_2026-10-01_hilda33d_DRAFT.md`
   with Marcus's verdict left as placeholders).
7. **Memory budgets.** The root `MEMORY.md` is 13.4 KB of content against a 12 KB soft budget (over before 10-03;
   today's edit was byte-neutral), and `INDEX_ccx.md` is 14.1 KB against 14. A trim pass per `INDEX_conv.md` is owed.

## 5. Non-obvious state
- **Compare on LIKELIHOOD over #15's 27 rows**, never on stored logposts. hilda34g's logpost carries the lag's flat
  prior and logit Jacobian (−1.7615) that no lag-0 mode has.
- **The lag-0 control refit is not registered**; it is the comparison arm, read by `diag_obj15_refit_read.R`.
- **`CM_DATE` in `diag_constraint_map.R` must move at every adoption.** The canonical's log is named by it, and a
  stale tag overwrote the previous canonical's log on 10-03 (restored from git).
- **App numbers typed in comments "at hilda33d"** are historical records. The live re-measure drivers are
  `diag_app_wobble_shares.R`, `diag_pulse_vs_tcre.R`, `diag_enso_growth_fit.R`, the scorecard and the constraint map;
  re-run them at every adoption.
- **The held Laplace ribbons** are still HELD (10-02 u). Their evidence is pinned to hilda33d by `test-futures-ribbons`,
  and the app's check refuses it at hilda34g. Shipping a band would need a rebuild at hilda34g and a ruling.
- **A suite run in a scratch git worktree with `data-raw/downloads` symlinked** reproduces the frozen-copy recipe, and
  runs the OSCAR regional-sheet test, so there is one skip fewer (3, not 4). Copy the outputs out before removing it.
- **The app preview `ccx-app`** answers on localhost:7788 on the adopted tree (restarted 10-03 22:37; 34-parameter
  banner, the ENSO switch reads "about 40 %").
- **Frozen trees:** `~/ccx_frozen/20261002ee_obj15_{lag,ctl}` are REMOVED (10-04 a), after a re-check of every item,
  0 mismatches. The chain's three launch files `~/ccx_frozen/20261002ee_obj15_launch.{sh,out,pid}` remain; their
  content is in `RUN_PROVENANCE.txt` and CHANGELOG 10-02 (ee).
- **Worktrees:** `compassionate-leavitt…` and `youthful-blackburn…` under `.claude/worktrees/` are older sessions'
  (Marcus's to remove); `pensive-burnell…` is the running background task.
- **Untracked, deliberately:** Marcus's `carbotopecomment.9.26.26.docx` and `carbotopecomments.10.2.26.docx` (worked
  through, never commit or edit), `outputs/mcmc_smoke/` and `outputs/diagnostics/smoke/`.
- **The multi-line-shell lesson recurred** (10-03 h): a failed `git add` on one line did not stop the commit on the
  next, and the commit held only a rename. It was caught by `git show --stat` and amended before the push. Stage,
  check `git diff --cached --stat`, then commit, as separate calls.
