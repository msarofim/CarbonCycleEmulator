# HANDOFF 2026-10-12 (e) — label `hilda_csl3v0kaidgbemwtc` BUILT, TESTED, PRICED; the refit is RULED, not yet launched

> ⚠ **SUPERSEDED 2026-10-12 by `notes/handoff_2026-10-12f_wtc_refit_armed.md`** (the refit launched; landing armed). Two claims here were wrong: `ccx_mode_start()` does NOT refuse hilda29e (the real failure was the migration's silent 0 fill), and the module check's stopping rule is 0.1 σ (ruled), not 0.01.

**Supersedes** `notes/handoff_2026-10-12d_citation_rulings_refit_plan.md` (which now points here). Written on Marcus's
request ("Yes, write the handoff note"), 2026-10-12.

- main = `2b7e860` before this note's commit, **pushed** (origin/main level). Nothing is running except the local app
  preview (§5) and the separate MANIFEST task session (§5).
- **Start here:** CHANGELOG **2026-10-12 (dd) and (ee)**; the rulings ledger `notes/citation_rulings_2026-10-12.md`
  (§D carries this session's four rulings, verbatim); memory [[ccx_wtc_label_built]] and [[ccx_nuclear_sh_gap]].

## 1. What was done

| step | outcome |
|---|---|
| **Routing** (the 10-12d handoff's "first decision") | Marcus: "New label (a) (Recommended)"; name "…wtc (c = cited)". Every changed value is a structure-block field whose ABSENCE is the old value, in both cores. `hilda29e` and every registered mode are bit-exact: `test-mode-file` reproduces −1108.1126; `hilda29e`'s stored logpost recomputes exactly. |
| **Data products** (handoff 10-12d §4 step 1) | `obs_glodap_surface_alk_sal.rds` (ALK 2303.3763, S 34.76018); `carbonate_coefs_s34760.rds` (seacarb 3.4.1 installed: "Install 3.4.1 (Recommended)"; the S 34.7 rebuild is `identical()` to the shipped table); `obs_glodap_{deep,intermediate,profile_cov,sigma_rep}_3682.2m.rds` (each 3700 rebuild reproduces its shipped file); `obs_d14c_intcal20_v2.rds` (column 5 = `sd_d14c`; legacy columns reproduce the rintcal table exactly; `rintcal` no longer needed); `forcing_nuc_nh_share.rds`. Each with a reproduction gate; the ALK and IntCal gates mutation-tested. |
| **Code, both cores** (step 2) | GLODAP products keyed by column depth (`ccx_glodap_file()`); the respiration and seasonal-SST lags are run inputs (C++ twins removed); forcing column `nuc_share_NH` (N_FORCING 20) with the `_of`/`_check`/stamp idiom; the ¹⁴C tag solve per month; ALK, carbonate table, depth (`ccx_grid_of()`), pump organic ε through one resolver each; the IntCal row's σ switch; the third gate `wtc_free` (`bomb_share_NH` logit U[0.77, 0.98], `seas_T_lag` logit U[0, 6]; inits at midpoints; default-param slots at the legacy 0.90 / 2.0); registry entries with citations; `P_canon` 1.88 (diagnostic, global). |
| **Tests** | New `test-wtc-label.R` (140): block provenance, the run carries every field, **R↔C++ parity under the label** (1983–2003, both new names off-default, test-parity tolerances, a power check), each field live. Label ledgers extended in nine files; column inventories classified (`nuc_share_NH`: NON-CLIMATE / OTHER, flagged). |
| **Pricing** at `hilda29e`, before any refit (`calibration/diag_wtc_batch_price.R`) | **+106.95 likelihood**: IntCal σ +96.79 (mostly the σ normalisation; those rows now weigh ~6×), photo ε +7.32, pump ε +3.06, depth +0.09, SST lags −0.27, ALK/salinity/nuclear ≈ 0. G1 and G2 identities both exactly 0. Output `outputs/diagnostics/wtc_batch_price_20261012/`. |
| **Full suite at `f2af594`** | **7909 passed, 2 failed (card 4, by design), 1 skipped**, 19.7 min (`outputs/diagnostics/suite_20261012_f2af594.log`). The run at `9967a63` had six failures this change caused; all fixed or handled as each test directs (CHANGELOG ee). |

## 2. Decisions (Marcus's, verbatim, in the ledger §D)

- **Routing:** "New label (a) (Recommended)"; "…wtc (c = cited)".
- **seacarb:** "Install 3.4.1 (Recommended)".
- **Refit procedure:** "Carry module, then check (Recommended)" — the stage-2 multistart runs directly under the label
  with `hilda29e`'s interannual-module values as pins; warm start = `hilda29e` with `bomb_share_NH` 0.90 and
  `seas_T_lag` 2.0 (its own model); dispersed starts draw the two from their priors; then the one-pass module check
  (`calibration/fit_iav_module.R --check`) at the new mode, and a second pass only if a module name moves > 0.01 σ.
- **Where:** "Mac overnight, #18's recipe (Recommended)" — Torch verdict said out loud (Mac ~2× faster per evaluation;
  Torch wins only 24-wide, which Marcus would submit).
- **Nuclear gaps:** "Keep the gaps (Recommended)".
- **The two red tests:** "Re-express both (Recommended)" (`test-enso-lag.R:267`, `test-ndep.R:42`).

**Mine, stated:** the B slab ends where the deep row begins (2000–2614.7 m at 3682.2; stream renamed
`d14c_mid_2000_2615`); `sigma_rep`'s h grid pinned to 30–200 m; the "constant" nuclear share emits 0.95 (not NaN) so a
built forcing carries no NA; the two gated names as default-param slots at their legacy values.

## 3. Files

- **New:** `data-raw/build_{glodap_surface_alk_sal,intcal20_d14c,nuc_nh_share}.R`; the eight `data/` products above;
  `calibration/diag_wtc_batch_price.R`; `tests/testthat/test-wtc-label.R`; the two suite logs.
- **Changed:** `R/{calibrate,carbonate,c14_tag,climate,constants,cpp,forcing,joos_irf,likelihood,model,periodic_spinup,spinup}.R`,
  `src/ccx_core.cpp`, `app/global.R`; `data-raw/build_{carbonate_tables,glodap_deep_targets,glodap_intermediate_targets,glodap_profile_covariance,glodap_sigma_rep}.R`
  (each takes its salinity / depth as an argument); `data-raw/download_data.R` + `MANIFEST.csv` (`intcal20`); tests in
  13 files (ledgers, inventories, the two re-expressions).

## 4. Next steps (in order)

1. **Extend the refit driver for the RULED procedure** (`calibration/run_dispersed_multistart.R`, env-driven:
   `CCX_MS_STRUCT`, `CCX_MS_PIN`, `CCX_MS_SEAS_ML`, …; `calibration/make_port_targets.R`).
   - `ccx_ms_reference_set()` (`R/calibrate.R` ~2751) REFUSES the canonical's pins under another label by design
     ("a cut canonical's pins are ruled under its own"). Add the ruled branch: canonical pins + struct
     `hilda_csl3v0kaidgbemwtc` + seas_ml 1 → incumbent `hilda29e` (a START, seeded with the two new names at 0.90 / 2.0),
     new basin the seas_ml-0 control. Keep refusing every other label.
   - `ccx_mode_start()` refuses a file lacking the two gated names ("fitted on a different parameter set (29 names; this
     build fits 31 …)"). The seeding must be EXPLICIT (the legacy values, = what `hilda29e` ran; both are encodable inside
     their boxes), not a widening of `CCX_PARAM_ABSENT_OK` (its contract is "the model it drives is absent").
   - Port targets under the pin set; preflight 24/24; then the landing kit: the land script, a read script for the new
     objective (from `calibration/diag_obj18_refit_read.R`), the basin decomposition BEFORE promoting
     (`calibration/promote_multistart_mode.R`, `lib_ms_promote.R`), and the module check.
   - #18's recipe (CHANGELOG 10-07 i): 24 starts, 8 at once, the CPU clock, 300 CPU-min per start, 3 restarts × 6 cycles
     × 6000 maxit, spread 1.0452; pins file + port-target log in the frozen tree; `nohup` + `caffeinate -i -s`; confirm
     the 8 WORK processes, not just the launcher. Check `uptime` first.
   - ⚠ **#18's own launch / land / chain shell scripts are NOT in `~/ccx_frozen_records_20261012.tar.gz`** (only their
     `.pid` files are). They went to `~/.Trash/ccx_frozen_20261012/` with the rest of `~/ccx_frozen` (10-12 cc), and
     this session could not read the Trash to confirm. **Recover `20261007i_obj18_{launch,land,chain}.sh` and the
     `20261008d_obj18p2_*` scripts from the Trash before it is emptied**, or rebuild them from CHANGELOG 10-07 (i)/(k)
     and 10-08 (c)/(d).
2. **Launch** on the Mac overnight from a frozen worktree under `~/ccx_frozen/`.
3. **Land**: read, basin decomposition, promote, the one-pass module check (second pass only if a module name moves
   > 0.01 σ), Hessian, then **Marcus's adoption ruling and the mode's name** (he names it).
4. **After adoption** (unchanged from 10-12d): the bomb-share identifiability check (posterior sd, correlation with
   `tau_ex` and `bomb_total`; fixed-proxy fallback); re-measure `ALPHA_AS_FCO3` at the new mode; MCMC (4 × 200k); the
   futures bands; the app and card numbers; the suite; the `v1.1` tag named after the new mode.
5. **Not on the refit's path, still owed:** the PHI_EFF NH product (the MOD17 amplitude-free argmin, with a reproduction
   test; `notes/constants_citation_needs_2026-10-12.md` row 15); the cite-as-is registry sweep and the "judgement"
   entries (ledger §B).

**Still Marcus's** (unchanged from 10-12d §4): the merged remote branch `origin/claude/recursing-hermann-a2f965`;
emptying the Trash (see the ⚠ above first); the flux-trace default; the app never SHOWING `retried` / `converged`; the
copy worklist; deploy items; card 4's two by-design failures and the other 10-12c items.

## 5. Non-obvious state

- **The MANIFEST task** ("Add MANIFEST rows for the nine nuclear 14C files") is running in a SEPARATE session, in the
  worktree `.claude/worktrees/compassionate-chatelet-52df58`. It will touch `data-raw/downloads/MANIFEST.csv` and
  `CHANGELOG.md`; merge with care. Its sha256 values must equal those stamped in
  `attr(readRDS("data/forcing_nuc_nh_share.rds"), "provenance")$file_sha256`.
- **Frozen worktrees kept:** `~/ccx_frozen/suite_20261012_{9967a63,f2af594}` (+ their `.sh` launchers). Removable
  (`git worktree remove`); the logs are committed.
- **App preview** `127.0.0.1:7788` (pid 44779) runs code from before this session. The canonical has not changed, so its
  numbers are the same, but restart it before any visual check (the forcing now has a 20th column).
- **seacarb 3.4.1 + oce, gsw, SolveSAPHE** are now in the system R library.
- **`test-wtc-label.R`'s fixture** builds the label from `hilda29e` via `ccx_mode_run_params()` with the two new names in
  `pm`; that works only because of the default-param slots (the overlay copies a gated name only where the base has a
  slot).
- **The new objective's logposts are NOT comparable to #18's**; compare arms on likelihood, and the new mode against
  `hilda29e` re-scored under the NEW label.
- **Memory sizes:** `INDEX_ccx.md` 14.9 KB (over its 14 KB soft budget, under 18 KB hard); `INDEX_ccx_inputs.md` 10.1 KB;
  `INDEX_ccx_app` 15.3 KB (unchanged).
