# HANDOFF 2026-10-08 — `hilda29e` ADOPTED (objective #18 pass 2, basin 1); the ledger applied; NEXT: the app text, with Marcus

> **UPDATE, later 10-08 (CHANGELOG (g), (h)): §3 items 1 and 2 are DONE except card 4's COPY.**
> - (g) Card 4 audited at `hilda29e` (`calibration/diag_card4_audit.R`, `outputs/diagnostics/card4_audit_20261008_hilda29e.log`):
>   - **three** typed claims are false: the lag; "a little below" (w 16.79 is inside 14–25); the growth-peak timing (model now 5 mo = the record's);
>   - "more El Niño-driven" is estimator-dependent;
>   - 60 % → 66 % and 1.5 → 1.0 ppm are wording calls.
> - §3.1(b)'s "1.248 mo" is basin 2's; the adopted basin 1 gives **1.207**.
> - (h) Marcus: "Both, now" — the lag test reads the lag the canonical RUNS, and the "a little below" test (promised in `review.R`, never written) exists. **Both FAIL until card 4's copy changes**: that is the remaining item, Marcus drafts.
> - (h) Marcus: "Main fit only" — the constraint map is REBUILT at `hilda29e` (`CM_DATE` 20261008e), test (6) passes, and a computed caption line says the El Niño settings are fitted separately (Claude's draft).
> - The suite at `1f9f904`: `outputs/diagnostics/suite_20261008_1f9f904_card4_cmap.log`.

**Supersedes** `notes/handoff_2026-10-07e_obj18_landing_armed.md` (its §3 is fully done).
Written on Marcus's request ("Approve all five, then write the handoff note").

**Start here.**
1. CHANGELOG 2026-10-08 (a)–(f), newest first:
   - (a): #18 landed;
   - (b): the ocean structure test;
   - (c): the kept-pair fix;
   - (d): pass 2 launched;
   - (e): adopted, and the app correction;
   - (f): the ledger applied.
2. Memory, shared store:
   - `ccx_hilda29e_adopted`: the adoption and its corrections;
   - `ccx_iav_cut_previewed`: the whole cut arc;
   - `objective_noise_floor_optimum_on_spike`: R's BFGS returns an unevaluated `par`;
   - `pinned_name_seed_vanishes`: the seed fix, merged.
3. `~/.claude/CLAUDE.md` and this repo's `CLAUDE.md`.

## 1. Where things stand

**The canonical is `hilda29e`.**
- What it is: objective #18, second pass, at basin 1, under the label `hilda_csl3v0kaidgbemwt`. That label is the interannual "cut" with a DETRENDED ENSO index.
  - 29 fitted names, 14 held: #16's ten, plus the module's four at the one-pass check's values (lag 5.9293 mo, land 0.66319 / 0.63560, `w_enso_l2` 16.7877).
  - `h_ml` 64.6 m; logpost −1166.949732; Hessian PD, cond 2.98e5.
- **The cut is a fixed point there.** The pass-2 check moved every module name less than 0.01σ: lag +0.000, land −0.000, w +0.001. The check has POWER: basin 2 moves w −1.224σ under the same procedure.
- What it buys: GATE V PASS (0.797 vs 0.933 ± 0.084; `hilda33p` 0.565, FAIL). The land ENSO lag is the growth record's.
- What it costs:
  - the ice cores, about −8 log-units;
  - the ocean's climate effect against GCB, 2.16× (`hilda33p` 1.87×). About 94 % of that is the detrended index itself, not the refit (10-08 b).
- **The app loads `hilda29e`.** `app_params()` reads `ccx_mode_file(CCX_MODE_CANONICAL)`; `APP_RELEASE_MODE` is only the label, now "hilda29e". The app is not public.
- **Code** is on `main`, pushed. The last commit before this note is `9e22e3b` (the ledger applied).
- **The full suite at `9e22e3b`** was running when this note was written: `outputs/diagnostics/suite_20261008_9e22e3b_ledger.log`, tree `~/ccx_frozen/suite_20261008_9e22e3b`.
  - **Expected:** exactly ONE failing test, `test-constraint-map.R` (6) `pv$mode`, by design (§3 item 2).
  - **RESULT (10:11 EDT): 7027 passed, 1 failed (exactly that one), 0 errors, 5 skipped.** The skips:
    - `{seacarb}` ×2;
    - the dormant held-at-0 test ×1 (§4);
    - **card 4's guard ×2** (`test-review-card-numbers.R` lines 33 and 57; §3 item 1). This note first said 4: card 4's guard is TWO tests.

## 2. Rulings this session (verbatim)

| Ruling | Context |
|---|---|
| "Remove all three. Check status." | the three worktrees |
| "Remove the wave tree; run the ocean structure-vs-parameter test" | |
| "Build the bookkeeping fix. Then provide details & recommendations on 1-3." | |
| "Basin 1, run the second pass, adopt if it passes" | |
| "hilda29e (Recommended)" | the canonical's name: 29 names, 'e' for 10-08 (e) |
| "Are there any more changes likely to happen to CarboTope? If not, I say move the app's release to the new model, because it hasn't been shared publicly yet, and we can start working on the text updates." | The answer: nothing in flight; the deferred bundle, H2 and `gamma_diff` are open; the cut's own text changes are settled. The app had in fact already moved. |
| "Approve all five, then write the handoff note" | 1. the label; 2. the ledger; 3. the cut-canonical guard; 4. the L2 constant; 5. the constraint map (BLOCKED, §3 item 2). |

## 3. NEXT

1. **⛔ CARD 4 IS STALE, AND ITS GUARD WENT SILENT.**
   - The app's card 4 says the land responds "2.5 months after the index"; `hilda29e` runs 5.93 months.
   - `test-review-card-numbers.R` (lines 31–61) SKIPS whenever the canonical does not FIT `lag_enso_land`. Under the cut it is pinned, so the guard skipped instead of failing. Its two tests are two of the suite's five skips, a silent gate (memory `skip_guard_silent_on_adoption`).
   - **Do with Marcus:**
     - (a) the card-4 wording (he drafts text; propose numbers only);
     - (b) re-express the guard to read the lag the canonical RUNS, fitted OR pinned, with the module's own sd when pinned (stage 1's Laplace sd 1.248 mo; the check file's `laplace`). Then the test FAILS on stale copy instead of skipping.
   - Both are test / copy changes: Marcus's.
2. **The constraint map ("What pins down what?") cannot be rebuilt at `hilda29e` as configured.**
   - `calibration/diag_constraint_map.R`'s own gates refuse it, by design (`outputs/diagnostics/constraint_map_20261008e_GATES_FAILED.log`):
     - `CM_FAMILY` carries `gcb_ocean_enso_slope`, which under the cut is a MODULE row;
     - the parameter union expects `gamma_enso_land_NH/SH` fitted; `hilda29e` pins them.
   - **Marcus to rule** how the tab treats the cut's held module names and the moved row (drop / declare as held / show the module separately).
   - Then set `CM_DATE` to `"20261008e"`, rebuild (`Rscript calibration/diag_constraint_map.R`, a few minutes), and `test-constraint-map` (6) passes. Until then the app's tab shows `hilda33p`'s map. `data/constraint_map.rds` is untouched.
3. **App text updates, with Marcus:**
   - card 4 (item 1);
   - the What-if numbers;
   - the wobble shares;
   - card 7's `k_w` line (a draft, never approved);
   - `NOTE_LUC_SPLIT`;
   - the scenario descriptors (drafts);
   - the sink→source caveat;
   - a Known-issues card for the ocean's climate effect (2.16× GCB).
   - Pre-launch: `APP_FEEDBACK_URL`, a public repo target, a start-up re-time, the plan limits, the account name, `APP_VERSION` / tag.
4. **Possible model changes, none ruled to proceed:**
   - the bundle Marcus ruled for "the next model change" (10-06 j): `ra_ratio` (+3.2; measured to leave futures / responses / pools unchanged), and the σ-audit trio (`gcb_ocean_sink`'s σ, `excess_c14_ocean`'s targets, `CCX_ICE_DISCREPANCY`; each an objective change and a ~9 h refit). #17 / #18 did not take them up;
   - H2: the ocean's thermal response. A GCB-sized one would lower SSP5-8.5 2300 by about 24 ppm (at `hilda33p`). Deferred, no ruling;
   - `gamma_diff`: open, no proposal.
5. **Products, not model changes:**
   - the cut posterior ("Laplace + propagation", RULED 10-06 o, not built; the app's ribbons are held by `APP_RIBBONS_HOLD`);
   - why detrending enlarges the ocean's climate effect: not decomposed;
   - the assessment's §5 / §7 and a version tag.

## 4. Non-obvious state

- **Removable trees, after their logs are committed:**
  - `~/ccx_frozen/20261008d_obj18p2` (pass 2's wave; landed and committed, `58ef6fc` / `79f4966`);
  - `~/ccx_frozen/suite_20261008_9e22e3b`.
  - Marcus has ruled removals case by case; ask.
- **Scripts outside the repo:** `~/ccx_frozen/20261008d_obj18p2_{launch,land,chain,chain_resume}.sh`. Copies are in `outputs/diagnostics/obj18p2_landing_20261008/`, and the launch script in the outdir's `logs/`.
- **The registry:**
  - `hilda29e` is the canonical;
  - `hilda33p` is the previous canonical;
  - `hilda29a0` / `hilda29a6` are PROVISIONAL names for #18 pass 1's basins 1 / 2;
  - `hilda29w` is #17's basin B.
  - The canonical's directory was renamed at adoption, from `refit_20261008_obj18p2_hilda_csl3v0kaidgbemwt_basin1`. The pass-2 module check file still names the old path in its provenance (md5s are content-based).
- **`ccx_ms_reference_set()` changed:**
  - the canonical's pins (they carry the module) are accepted ONLY under its own label and seas_ml;
  - the pass-2 and layer-2-limb branches are removed;
  - `CCX_MODE_L2_ARM_PINS` = the limb arm's own nine (`CCX_MODE_OBJ15_PINS`), so a nine-pin array is refused (the 10-06 reason the old alias existed);
  - #16's ten pins match NO ruled set: a #16 re-run must rule its own.
- **The multistart driver changed** (10-07 m, 10-08 c):
  - a seeded slot moves only fitted names, and an unseedable one runs a labelled dispersed draw;
  - duplicate starts are refused;
  - `best` is always f(the kept u) (`ms_kept_pair()`);
  - the DEAD gate has an exact identity branch, "UNPAIRED BEST". Start files carry `dead_branch`, `claim_gaps`, `pairing`.
  - A PINNED new-basin reference is labelled as such.
- **#18 (pass 1)'s id 13** stays recorded `dead` in its start file. It was a false positive of the old pairing (10-08 a); the statement is in CHANGELOG (a).
- `test-l2-enso-limb.R`'s "held at 0" test is DORMANT: no registered mode holds `w_enso_l2` = 0 with the shim at 0. It skips, as it has since 09-20 r.
- **Untracked files that are NOT this session's:** `carbotopecomment.9.26.26.docx`, `carbotopecomments.10.2.26.docx`, `outputs/diagnostics/smoke/`, `outputs/mcmc_smoke/`. Leave them.
- The Mac was on AC throughout; no long job is running except the suite named in §1.

## 5. Files from this session

- **New:**
  - `calibration/lib_ms_seed.R`, `calibration/diag_obj18_dead13.R`, `calibration/diag_obj18_ocean_struct.R`;
  - `tests/testthat/test-ms-seed.R`, `tests/testthat/test-ms-kept-pair.R`;
  - `outputs/diagnostics/{ms_seed_fix_20261007, ms_kept_pair_20261008, obj18_landing_20261008, obj18p2_landing_20261008, obj18_ocean_struct_20261008}/` and their logs; `obj18_vmmin_synthetic.{R,log}`.
- **Changed:**
  - `calibration/run_dispersed_multistart.R`, `collect_dispersed_multistart.R`, `lib_ms_deadline.R`, `diag_obj18_basins.R`;
  - `R/paths.R`, `R/calibrate.R`; `app/global.R` (the label);
  - `README.md`; `calibration/torch/make_bundle.sh`;
  - the ledger's 10 test files (CHANGELOG f).
- **Outputs:**
  - #18's landing: `multistart_20261007i_*`, `refit_20261008_obj18_*`;
  - pass 2: `multistart_20261008d_*`, `refit_20261008_hilda29e_*`, `refit_20261008_obj18p2_*_basin2`, the module check files.
