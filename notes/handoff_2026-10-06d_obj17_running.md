# HANDOFF 2026-10-06d — OBJECTIVE #17 BUILT; STAGE 2 RUNNING ON THE MAC OVERNIGHT

**Supersedes** `notes/handoff_2026-10-06c_iav_cut_build.md`, whose §3 build order this session executed through
step 8. That note's §3 steps 9–11 and its open design points are carried below. Its §5 non-obvious state is
superseded by §5 here.

**Start here.**
1. This note's §4: the landing, with exact commands.
2. CHANGELOG 2026-10-06 (o): everything built and measured this session, every number.
3. Memory, shared store:
   - `ccx_iav_cut_previewed`: the arc, now with a BUILT section;
   - `pinned_value_reset_by_fitted_resolver`: the bug this build found;
   - `r_parser_17_digits_not_round_trip`: why the pin literals are within 1 ulp, not bit-identical.

## 1. What happened this session
- **Four rulings** (Marcus, verbatim):
  - "hilda_csl3v0kaidgbemw (Recommended)": the label (w = wobble);
  - "One pass + check (Recommended)": re-run stage 1 at stage 2's values; stop if each module name moves less than 0.1 of
    its own stage-1 1σ; a larger move comes back to Marcus before any second refit;
  - "Laplace + propagation (Recommended)": the cut posterior. Stage 1's Laplace covariance is propagated into the other
    names through the main objective's cross-Hessian;
  - "Remove it (Recommended)": `~/ccx_frozen/20261006_iavcut_54d85e5` is removed (outputs checked md5-identical first).
- **Built** (commits `1ce5018`, `edc0cd0`, `be223f0`, `20a89f8`; see CHANGELOG (o) for the file-by-file list):
  - the label and its guard: the module's four names must be PINNED under it (logpost and reference set both refuse
    them free);
  - the low-pass `gcb_land_sink` row and the slope row's switch;
  - the module's estimator and its data product (`data/mbl_global_growth_monthly.rds`);
  - the stage-1 fitter `calibration/fit_iav_module.R`, the pricing driver `calibration/diag_obj17_price.R`;
  - the #17 pins (`CCX_MODE_OBJ17_PINS`) and the reference-set branch.
- **⛔ A latent bug, found and fixed:** a PINNED ENSO amplitude was reset to 0 inside the objective. It never moved a
  stored number (every pin set held the ocean pair AT the default 0), but #17 pins the land pair at 0.66 / 0.63.
- **Stage 1 at hilda33p:** lag **5.8432** months, land **×1.30120** (0.66071 / 0.63322), `w_enso_l2` **14.7262**.
  - Profile: 1σ 4.46–7.28, 2σ 2.88–8.99; the canonical's 2.61 is outside 2σ.
  - Laplace 1σ: lag 1.25, scale 0.294, `w_enso_l2` 1.28.
- **Priced on the canonical, on #17's own rows:** B1 −10.86 unrefitted; B2 −10.25 (five land names re-optimised), of which
  the seasonal rows −13.25. SSP5-8.5 2300 −3.53 ppm, vvH −1.78. The built objective reproduces the preview's B1 to 3.7e-11.
- **Tests:**
  - `test-iav-cut.R` 119 / 0, nine source mutations caught;
  - `test-ms-reference-set.R` (12) 23 new (the file 90 → 113 / 0), five mutations caught;
  - full suite at `1ce5018`: **6550 passed, 0 failed, 3 skipped**, rc 0 (= `15dbda6`'s 6427 + 123, each counted);
  - full suite at `20a89f8` (the launch commit): **6573 passed, 0 failed, 3 skipped**, rc 0 (= 6550 + test (12)'s 23).

## 1b. The landing DRY RUN, 21:54-22:16 (CHANGELOG 2026-10-06 p)
- On the first finished start (`start_001`, the incumbent seed; ONE of 24, so a preview, not the read), in a separate
  tree, the whole chain ran: collect → promote → Hessian → read → the one-pass check.
- **⛔ It caught a SECOND pinned-value bug:** promote's GATE 5 rebuilt the start through `ccx_overlay_par()` on a
  hand-built base and lost the pinned land ENSO pair (gap 39.1). **Fixed in `0a4e89f`** (the overlay keeps the process's
  pins; the promote base carries the `pins` attribute; test IC11). The refit itself was never affected.
- **With the fix every step PASSES:** GATE 5 gap 2.1e-14; Hessian PD, condition 2.9e5; the read's every section.
- **Preview numbers:** #17's rows −9.32 against REF (pricing B2 −10.25); #16's rows −39.24; SSP5-8.5 2300 −4.33 ppm,
  vvH −3.04.
- **⚠ The one-pass check FLAGGED `w_enso_l2`:** re-running stage 1 at that start moves it 14.73 → 16.71 (**+1.55σ**),
  while the lag (+0.010σ) and the land scale (−0.021σ) hold. Stage 2 has no slope row and moved names that set the ocean's
  ENSO response, so the slope row fell +2.79 → +1.85 at fixed `w`. If the real landing shows the same, the ruled check
  sends it to Marcus: accept the one pass, iterate (another overnight refit at `w` ≈ 16.7), or change the design.
  Evidence: `outputs/diagnostics/obj17_dryrun_20261006/`.
  - **Which names, UNTESTED:** at start_001 the largest ocean moves were `pump_grad` −0.88 sd, `hs_asx_frac` +0.44, `k_w`
    −0.41, `kz` +0.40 and `u_hs` −0.34 (hilda33p's marginal sd). My hypothesis: a weaker solved pump leaves a smaller DIC
    contrast for the limb to move per unit exchange, so the slope falls at fixed `w`. **The test:** at the landed
    vector, take the slope row's derivative with respect to each moved ocean name (one at a time, the others held) and
    see whose product with its move accounts for the +2.79 → +1.85 drop. Do it before framing the choice for Marcus.

## 2. The run
- **What:** objective #17's stage 2. Label `hilda_csl3v0kaidgbemw`, 14 pins (#16's ten + the module's four), 29 free names.
  24 dispersed starts, 8 at a time, on the CPU clock: 300 CPU-min per start, 3 restarts × 6 cycles × 6000 maxit,
  spread 1.0452.
- **Where:** the frozen worktree `~/ccx_frozen/20261006x_obj17` at `20a89f8`.
  - The git-ignored `data-raw/downloads` entries are SYMLINKED to the repo's (14/14 inputs).
  - Port targets were regenerated in the tree (`logs/port_targets_20261006o.log`). The incumbent hilda33p seeded at the
    pins evaluates to −1166.456; its +21.0 offset from the stored logpost is the objective change, not a port defect.
  - Preflight: 24/24 exit 0, LAUNCHABLE, every port VERIFIED; 0.347 CPU-s/eval at id 1 (`logs/preflight_20261006o/`).
- **Launch:** `~/ccx_frozen/20261006o_obj17_launch.sh` under `nohup`, **2026-10-06 19:26:02 EDT**, launcher PID 6620;
  8 work processes confirmed at launch.
  - PID file `~/ccx_frozen/20261006o_obj17_launch.pid`; chain status `~/ccx_frozen/20261006o_obj17_launch.out`.
  - Logs: the tree's `logs/wave_20261006o.log` and `logs/ccx_multistart_mac_20261006o_<id>.out`.
  - The outdir is NAMED (`multistart_20261006o_hilda_csl3v0kaidgbemw_seasml1_pin_obj17_sd1.0452`): the driver's
    default carries the 14 pins and would be 379 bytes, over macOS's 255-byte limit.
- **Expected:** ~13–16 h, i.e. late morning to early afternoon of 2026-10-07. Keep the Mac on AC; the launcher holds
  `caffeinate -i -s`.

## 3. What to expect when it lands
- **On #17's own rows** the refit should land near the pricing's B2 (−10.25 against hilda33p scored on #17's rows,
  REF = −1119.9835 likelihood). The preview's B3 (seasonal names freed too) did not recover the seasonal rows, so
  little better than −10 is expected.
- **The futures** should move by roughly −3.5 ppm (SSP5-8.5 2300). A move of tens of ppm would be a red flag:
  `gamma_diff` is held, and its absence is what kept the fertilisation pair still in the preview.
- **⚠ Compare on LIKELIHOOD, never stored logposts.** #17 pins four names #16 fits, so the prior terms differ. The two
  objectives also score DIFFERENT rows. Read both vectors on BOTH objectives (§4 step 4).

## 4. THE LANDING, in order
1. **Finished?** `cat ~/ccx_frozen/20261006o_obj17_launch.out` must show `objective #17 end … rc 0`. Confirm no work
   process remains: `pgrep -f "R.*--file=calibration/run_dispersed_multistar[t].R"` (the bracket keeps it from
   matching itself).
2. **Copy into the repo:** `bash ~/ccx_frozen/20261006o_obj17_land.sh`.
   - It verifies, copies, cmp-checks every file, and only then writes `RUN_PROVENANCE.txt`.
   - It refuses to overwrite an existing outdir.
3. **Collect, promote, Hessian** (the landing script prints the first command):
   - `CCX_MS_OUTDIR=<repo outdir> Rscript calibration/collect_dispersed_multistart.R | tee <outdir>/collect_<date>.log`.
     Read the basins and the convergence counts, and note how many starts ran out of time.
   - Promote (the script derives the best id itself, GATE 3; GATES 1–5 must pass):
     ```
     Rscript calibration/promote_multistart_mode.R --name=obj17_hilda_csl3v0kaidgbemw --outdir=<repo outdir> --dest=calibration/output/refit_<date>_obj17_hilda_csl3v0kaidgbemw
     ```
   - Then `Rscript calibration/recompute_hessian.R <mode file> --update`.
   - ✅ **The chain is DRY-RUN TESTED on start_001 at `0a4e89f`** (§1b): promote's GATE 5 needed the overlay fix; collect,
     promote, the Hessian, the read and the check all pass. ⚠ Run the landing from code at or after `0a4e89f`.
     `CCX_MODE_FILES` registration is still untested, and registering a mode is a separate act from ADOPTING it.
4. **Read:** `Rscript calibration/diag_obj17_refit_read.R` (written this session on #16's model).
   - It was dry-run on a SCRATCH #17 file: hilda33p with the module pinned at stage 1's values, which is the pricing's
     B1. Every section ran and reproduced the pricing (B1 −10.8609; #16's rows −39.45; the module +2.5622).
   - ⚠ Its survey and promoted-id checks had no starts to read. Run it once on the first finished REAL start
     (promoted to a scratch dest, `CCX_O17_TAG=_DRYRUN`) before relying on them.
   - What it reads:
   - each vector reproduces its stored logpost in its own space;
   - **#17 vs REF on #17's rows** (REF = hilda33p with its own module values, the pricing driver's `score17(MOD_OWN)`);
   - **#17 vs hilda33p on #16's rows** (the full land row and the slope row): the cut's total price in #16's terms
     (the preview's raw-row B2 was −39.2);
   - the module's own likelihood at both points (`ccx_iav_module_loglik()`);
   - the prior ledger (the free sets differ by the four module names), the moves in hilda33p's marginal sd, the futures
     (hilda33p; B1; #17), the land's net climate effect.
5. **The one-pass check (RULED):** `Rscript calibration/fit_iav_module.R --base=<the promoted #17 file>
   --check=calibration/output/iav_module_20261006_hilda33p.rds`. VERDICT STOP = every module name moved less than
   0.1 of its stage-1 1σ. Otherwise it goes to Marcus before any second refit.
   - ⚠ **Expect it to flag `w_enso_l2`** (§1b: +1.55σ at start_001); the lag and the scale held to ≤ 0.02σ there.
6. **Then:** the scorecard, the constraint map, the gate ledger, the ocean-climate diagnostic. Adoption is Marcus's call.
7. **The cut posterior ("Laplace + propagation"), after adoption or for the read:**
   - Stage 1's covariance is in the stage-1 rds (`$laplace$cov`, and `$laplace$cov4` on the four pinned names).
   - Still to build: the main objective's cross-Hessian between the 29 free names and the four module names (the
     module names stay pinned, so vary the PIN values and rebuild the logpost per step; the guard refuses them free).
   - Then the joint Gaussian: Cov(θ₂) = H₂₂⁻¹ + B Σ₁ Bᵀ, with B = −H₂₂⁻¹ H₂₁. `build_futures_ribbons.R` draws from it.
8. **The app copy** (handoff 10-06c §3 step 11): card 4's timing disclosure becomes obsolete; the What-if numbers; the
   wobble shares. ⚠ `tests/testthat/test-review-card-numbers.R` will FAIL by design once the lag moves. Update the copy
   WITH Marcus, not the test.

**Still open, Marcus's:** `gamma_diff`'s own future (an AOD term made zero-mean), separate from #17.

## 5. Non-obvious state
- **Running:**
  - objective #17's stage 2 (above);
  - the `ccx-app` preview on localhost:7788, as before.
- **Frozen trees** (all detached worktrees of this repo):
  - `~/ccx_frozen/20261006x_obj17`: the RUN. Do not touch until landed. Its `calibration/torch/port_targets.csv` is
    modified IN THE TREE ONLY (#17's targets); `main`'s copy still holds the canonical's.
  - The two suite trees (`suite_20261006_1ce5018`, `suite_20261006_20a89f8`) are REMOVED; their logs are in
    `outputs/diagnostics/`.
  - `~/ccx_frozen/20261006o_obj17_dryrun` at `0a4e89f`: the dry run's tree (scratch promote dest, its Hessian, the
    read's outputs). Removable once the landing is done; its logs are copied into `outputs/diagnostics/obj17_dryrun_20261006/`.
  - The suite trees at `0a4e89f` and `0c585fc` are REMOVED. At `0c585fc` the suite is CLEAN, 6598 / 0 / 3 (at `0a4e89f` it failed 2, the mode-struct lint on the new read script, since fixed).
- **The landing dry run RAN** (21:54-22:16; §1b). Its script `~/ccx_frozen/20261006o_obj17_dryrun.sh` can be re-run by
  hand on any finished start (it reuses its tree).
- **Early eval rates** (19:27, ~1 min in): 0.31–0.34 CPU-s/eval for the seven warm starts, 1.16 for the cold id 0
  (#16: 0.23–0.41, cold 1.23).
- **The pin literals are within one ulp, not bit-identical.** R's parser mis-rounds `w_enso_l2`'s 17-digit literal by
  1.8e-15. The launch string parses the same way, so the run's pins ARE `CCX_MODE_OBJ17_PINS` exactly. The test holds
  both facts.
- **The bug fix changes nothing stored**, but any OLD diagnostic that pinned a non-zero ENSO amplitude through
  `ccx_make_logpost()` would have been wrong. None was found.
- **Same call shape, not fixed:** `calibration/lib_seas_limbs.R` `sl_run()` calls `ccx_set_enso(p, pv)`. Its callers pass
  full vectors, so it is harmless there.
- **Smoke outputs** of the two new drivers are in `outputs/diagnostics/smoke/` (untracked, as before).
