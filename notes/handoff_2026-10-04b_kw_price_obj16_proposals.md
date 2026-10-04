# HANDOFF 2026-10-04 (b) — the `k_w` price arm is RUNNING; two objective-#16 proposals await Marcus; the greening reading is tested

**Supersedes** `notes/handoff_2026-10-04_hilda34g_adopted.md`, whose open items are all closed or in progress here
(§4). Self-contained.

**Start here.**
1. Read this note.
2. Then CHANGELOG 2026-10-04 (d)–(i), newest at the top of `CHANGELOG.md`.
3. Then memory `ccx_greening_sign_set_by_lag` and `ccx_kw_hemispheric_balance` (its status line), both routed from
   `INDEX_ccx_phi.md` / `INDEX_ccx.md`.

✅ A session launched from `CarbonCycleEmulator/` loads the shared memory store (verified 10-04 h). It does NOT load
`FaIRtoFrEDI/CLAUDE.md`.

## 1. What was done (10-04 d → i)
- **(d)** The substep-controller fix (branch `claude/pensive-burnell-a9bf40`, Marcus: "Apply A+B+C") is **merged into
  `main`** (`11dda49`).
  - Its code is byte-identical to `a7eab97`, whose suite was 6039 / 0 / 3 / 0.
  - `test-stability.R` passes on the merged checkout. No registered mode moves.
- **(e)** **The greening reading is TESTED** (pre-registered): the land ENSO lag SETS the sign of `npp_tsens`.
  - f = 0.92 / 0.89 in the two bases. The lag + the land block alone also recover 93 % of the lag arm's likelihood
    gain and its whole ~27 ppm futures move.
  - At lag 0 the GCB land sink pulled the term negative (an ENSO-timing patch). With the lag, ice-core CO₂ and the
    seasonal rows set it positive.
  - The sign is WEAK: f = ½ is only 0.33–0.42 logpost worse.
  - Two post-hoc checks: the slope gate was curvature-blind off the base, and the profile settled it (memory
    `whitened_slope_gate_blind_off_base`).
- **(f)** Marcus's rulings (below). The **price-arm rule** in `ccx_ms_reference_set()`: the canonical's pins + ONE ruled
  read name (`CCX_MS_PRICE_ARM_NAMES` = `k_w`).
  - A general first version failed the previously passing `pump_grad` guard (`test-ms-reference-set.R:51`). The test was
    not touched; the rule was narrowed.
  - Test (10); 4 mutations caught.
- **(g)** **The `k_w` = 1446 price arm is RUNNING** (§3).
- **(h)** The hilda34g assessment is DRAFTED, with Marcus's §5 / §7 as placeholders. The root `MEMORY.md` is trimmed to
  12,117 B of content (soft 12,288).
- **(i)** **The two objective-#16 proposals** (§2), on a committed preview (`calibration/diag_obj16_preview.R`,
  `outputs/diagnostics/obj16_preview_20261004.*`). In both, the honestly-weighted version does almost nothing.
  - **Timing row:** at its measured weight (n_eff 22.7 monthly / 44.8 annual) it moves the lag 2.64 → 2.75 / 2.90
    months. Reaching ~5 needs 5–10× n_eff, the 09-26 "loud" objection. **Recommended: no row; a card-4 disclosure.**
  - **Greening prior:** no literature-centred prior moves the sign. The profile's sd is 0.0085 against the literature's
    0.029, and zero is 1.1 sd from the optimum.
    - ⚠ The model's net climate effect on the land sink is +0.12 GtC/yr against GCB's −0.8 ± 0.7.
    - **Recommended: P3 (a GCB net-climate row, `q10` freed, previewed first) or P4 (pin at 0: −0.26 likelihood,
      +13.5 ppm at SSP5-8.5 2300).**

## 2. Rulings (Marcus, 2026-10-04, verbatim labels)
- "Draft a timing-row proposal" (the lag vs the atmosphere's 5-month timing)
  → `notes/proposal_2026-10-04_enso_timing_row.md`.
- "Revisit the npp_tsens prior" (the greening sign) → `notes/proposal_2026-10-04_npp_tsens_prior.md`.
- "Keep the family (Recommended)" (the "δ¹³C in ice cores" label): closed, no change.
- "k_w refit at 1446, hilda34g assessment, Memory trim, Remove merged worktree" (all done or running).
- "Canonical incumbent, Mac (Recommended)" (the `k_w` refit's reference set and machine).
- "Archive session, then remove (Recommended)" (the merged worktree: done; the remote branch stays).

## 3. THE RUNNING JOB: the `k_w` = 1446 price arm
- Frozen worktree `~/ccx_frozen/20261004f_kw1446` at `773f8f2`, `nuclear14c` copied in.
- Launch script `~/ccx_frozen/20261004f_kw1446_launch.sh` (PID in `…_launch.pid`, chain status in `…_launch.out`).
- Started 12:39 EDT 10-04; 24 starts, 8 at a time. **Expected ~00:00–01:00 10-05.**
- Measured 0.32–0.35 s/eval per task; the cold start, id 0, 1.2 s.
- Output inside the tree:
  `calibration/output/multistart_20261004f_hilda_csl3v0kaidgbe_seasml1_pin_…_k_w=1446_sd1.0452_sdby_npp_tsens=0.0291/`.
- Logs: the tree's `logs/wave_20261004f.log`, `logs/ccx_multistart_mac_20261004f_<id>.out`, `logs/preflight_20261004f/`.
- ⚠ Check that it is alive with `ps` for `run_dispersed_multistart`, or `kill -0 <pid>`. Never use a `pgrep -f` loop on
  the script name: it matches itself.

**Landing steps** (the 10-03 precedent):
1. Copy the outdir back into the repo's `calibration/output/`, byte-identical, with the logs, the preflight logs and
   `port_targets.csv`. Write a `RUN_PROVENANCE.txt` the way the #15 waves' copies have one.
2. `CCX_MS_OUTDIR=<dir> Rscript calibration/collect_dispersed_multistart.R`: count converged starts and basins.
3. `Rscript calibration/promote_multistart_mode.R --outdir=<dir> --name=kw1446_hilda_csl3v0kaidgbe` (GATES 1–5), then
   `Rscript calibration/recompute_hessian.R <mode file> --update`.
4. **The read, on LIKELIHOOD** (a pinned arm's logpost has no `k_w` prior; never compare logposts):
   - hilda34g's −1143.2508 on the 27 rows minus the arm's best = **the profile price of 1446**, with the `k_w` prior's
     own term at 1446 vs 1903 beside it.
   - Set it against the conditional price (1783) and the Laplace one (~47).
   - Run the scorecard with `CCX_SC_EXTRA_MODE=kw1446=<mode path>`: rows by group, gates, futures.
   - Name what absorbs `k_w`: the ridge partners `hs_asx_frac`, `bomb_total`, `u_hs` (memory `ccx_kw_hemispheric_balance`).
5. Nothing is adopted: this is a price, not a candidate canonical.

## 4. Open items, in order (each is Marcus's to prioritise)
1. **Land the `k_w` price arm** (§3).
2. **Marcus's rulings on the two proposals** (`notes/proposal_2026-10-04_enso_timing_row.md`,
   `notes/proposal_2026-10-04_npp_tsens_prior.md`).
   - If he takes P3, preview it first: the land block + `q10`, with the net-climate row computed INSIDE the objective
     (~3× the evaluation cost; `br_net_climate()` in the library already computes the row's quantity).
   - Any objective change is packaged as ONE objective #16 (priced on every registered mode and restamped, the D1
     precedent), then a refit.
   - If he takes the card-4 disclosure, draft the sentence for HIS wording.
3. **The assessment's verdict** (`notes/assessment_2026-10-04_hilda34g_DRAFT.md` §5, §7).
4. Optional, needs a ruling: extend the substep fix's held-K rule to `ccx_tr_box_eigbound()` (an objective change for
   tr-box structures only).
5. Housekeeping:
   - the remote branch `claude/pensive-burnell-a9bf40` is merged and could be deleted on GitHub (Marcus's call);
   - the two older worktrees (`compassionate-leavitt…`, `youthful-blackburn…`) are still Marcus's to remove.

## 5. Non-obvious state
- **Compare on LIKELIHOOD over #15's 27 rows**, never on stored logposts. The lag's flat prior and Jacobian sit in
  hilda34g's; a pinned arm has no prior for its pinned name.
- `calibration/lib_block_reopt.R` holds the block re-optimisation machinery. `diag_greening_lag_swap.R` keeps its own
  verbatim copies, so its recorded outputs stay reproducible.
- Its slope gate is **curvature-blind off the base**. Read a failed gate with two starts or a held profile, never with
  a finite-difference Newton step, without first evaluating the objective AT the step.
- The greening run's post-hoc outputs carry `_posthoc`. A first Newton summary that misread the cells was never
  committed (it sits in the session scratchpad).
- **The app preview** (`ccx-app`, localhost:7788) runs the merged tree. Since the substep fix the canonical still runs
  at 4 substeps; no number moved.
- **Untracked, deliberately:** Marcus's two `.docx` files, `outputs/mcmc_smoke/`, `outputs/diagnostics/smoke/`.
- **The multi-line-shell lesson:** stage, check `git diff --cached --stat`, then commit, as separate steps.
