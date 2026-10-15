# HANDOFF 2026-10-14c: suite read, copy facts at hilda31w, the nuclear ¹⁴C source promoted to data/

> ⚠ **SUPERSEDED by `notes/handoff_2026-10-15_prepublic_review.md`** (2026-10-15).

**Supersedes** `notes/handoff_2026-10-14b_band_shipped.md` (which now points here). Written on Marcus's
request ("Yes, write the handoff and remove the two suite worktrees"), 2026-10-14 ~12:20.

- ⭐ **UPDATE, later 10-14 (same day):** §3.3 IC8 is DONE (CHANGELOG (m), `f451f0f`). §3.4's pure-R guards were
  MEASURED (n) and then LANDED (o), `bcaa1f9`, with `test-run-r-guards.R`; the suite reads 8059 / 3 / 1, the same three reds.
  The seven calibration scripts they now stop are FIX ON TOUCH (ruled; f2 also needs a deposition-past-2025 ruling).
  The smoke chains are KEPT (ruled). The scratch worktrees are removed.
- **Start here:** CHANGELOG **2026-10-14 (g) → (k)**; memory [[ccx_worktree_needs_downloads_linked]]
  (now "FIXED AT THE SOURCE") and [[ccx_app_beta_blockers]] (deploy blocker CLOSED).
- main = `61421c6` + this note's commit, **pushed**.
- The tree is clean apart from the three CarboTope `.docx` files in the root (Marcus's, untracked by convention).
- **Nothing is running.** No frozen worktrees remain; `~/ccx_frozen/` holds only launch scripts, logs, pid files
  and `20261013_mcmc_hilda31w_smoke_chains/` (see §4).

## 1. What was done this session

| step | commits | outcome |
|---|---|---|
| (i) suite @`4acb215` read | `5d74e9a` | **8040 / 3 / 1.** The three reds are the expected ones: app-version, card 4 ×2. cmap-tie and futures-ribbons are now green. Nothing new is red. |
| (g) copy facts at hilda31w | `175c8e7` | `notes/ship_copy_facts_2026-10-14_hilda31w.md` (facts only; supersedes the 10-09 numbers). The 10-09 note and the 10-12 worklist now point to it. |
| (h) deploy gap measured | `a060d44` | `DEPLOY.md` excluded `data-raw/`, but the app read `nuclear14c` at run time. Absent, Δ¹⁴C NH is −3.9 ‰ by 2024 (≈0.7 × `sigma_d14c` 5.37); CO₂ / δ¹³C are unchanged. Record: `outputs/diagnostics/deploy_nuclear_absent_20261014/`. |
| (j) source promoted (ruled) | `ea29022` | `data/forcing_nuclear_c14.rds` (`data-raw/build_nuclear_c14_source.R`; each file's sha256 checked against MANIFEST). `ccx_nuclear_c14_annual()` STOPS without it. Before/after `identical()` on the source + 3 forcings. `test-nuclear-c14-source.R` 10 / 0, mutation-tested 4 ways. |
| (k) suite @`ea29022`, twice | `61421c6` | **Linked 8050 / 3 / 1**: bit-identical, the same 3 reds. **Unlinked 8035 / 4 / 5**: no objective test fails, so the worktree trap is closed. The extra red is `test-iav-cut.R` IC8 (§3.3). |
| cleanup | — | All 8 frozen worktrees removed: the six ruled, plus the two suite trees on Marcus's word. Each output was `cmp`'d against its landed copy first. Main's `data-raw/downloads/` intact (81). |

**Key numbers in the copy facts note:**
- 31 varied (`seas_T_lag`, `bomb_share_NH` added) and 14 held, identical to hilda29e's, so the label's "fourteen" holds.
- Strict R-hat max 1.241 (`seas_T_lag`), 14 of 32 above 1.01, min bulk ESS 13.
- In band units: chains ≤ 4.76 ppm (21 %), cell R-hat ≤ 1.036.
- `h_ml` 2.94× its Laplace sd, against the substep cap (not the floor).
- A Gaussian band cannot be built at hilda31w.
- The widest 2150 GMST band is vvH (0.0847 °C).
- ⚠ Pixel sizes are scaled from the 10-09 browser measurement, NOT re-measured.

## 2. Decisions (Marcus, verbatim, 2026-10-14)

- The ¹⁴C fix: **"Promote to data/ .rds + stop() (Recommended)"**.
- The release: **"We can wait until the current set of work is done, and then set the new version."**
- Frozen worktrees: **"Remove all six (Recommended)"**. Then: **"Yes, write the handoff and remove the two suite worktrees"**.
- **Mine, stated:**
  - The `.rds` stores per-year **GBq**, not mol; the loader converts with `MOL_C14_PER_GBq` as before. That keeps the constant in `R/constants.R` and the double bit-identical.
  - The old reader's body survives as `ccx_nuclear_c14_sum_files(dir)`, build-time only, with **no default `dir`**. So `grep 'ccx_path("data-raw"' R/` finds nothing, and test N4 enforces it.
  - No opt-out flag on the `stop()`. No legitimate caller wants a zero source. The one diagnostic that zeroes it (`deploy_nuclear_absent_20261014/`) overrides the function itself.
  - `data-raw/build_nuc_nh_share.R`'s gate now reads the model's `.rds`. It was re-run to a SCRATCH path only (identical bar the build date); the committed `data/forcing_nuc_nh_share.rds` is untouched.
  - `make_bundle.sh` no longer ships `data-raw/downloads/nuclear14c`.
  - IC8 was **reported, not edited** (§3.3).
  - The 10-13 smoke chains were kept, not deleted, because they had never been landed.

## 3. Open items, in order

1. **Copy, all Marcus's.** Numbers in `notes/ship_copy_facts_2026-10-14_hilda31w.md`; locations in `notes/beta_copy_worklist_2026-10-12.md` §A (its numbers are superseded, its file:line still hold).
   - **The band's four items**, then `APP_RIBBONS_HOLD <- NULL` in the SAME commit:
     - the label: `promote_futures_ribbons.R --label=`, with the hilda31w command in the facts note §A;
     - card 6 (`app/R/review.R`; its title is already false today);
     - the parameter panel's "not yet a posterior" clause (`app/global.R` ~355);
     - `APP_RIBBON_NOTE_TEMP`.
   - **"influenced about equally by X (a%) and Y (b%)"** (`app/global.R:939`) now also covers unequal-share ties: CO₂ level, 34 % vs 22 %.
   - Card 7's "slightly" (`review.R:772`) against +6.21; card 8's draft (`review.R:781`).
2. **The release**, ruled to wait until the current work is done:
   - v1.0 vs v1.1 (`APP_RELEASE_MODE` is still `hilda29e`, so app-version stays red);
   - then the full suite, then the tag.
3. **`test-iav-cut.R` IC8** (`:194–203`) sha256s the RAW `data-raw/downloads/mbl_zonal_co2_GL.txt` with no skip.
   - It fails in any tree without the downloads; its four sibling provenance tests skip.
   - Fix: a `skip_if_not(file.exists(...))` on that one expectation. That is a test change, so Marcus's call.
4. **Design questions still open (Marcus):**
   - **The pure-R core runs none of the four forcing guards.**
     - `ccx_run_prepared()` (`R/cpp.R:555–558`) checks the ENSO index, AOD mode, `nuc_share` and ndep; `ccx_run()` (`R/forcing.R` ~1342) checks none.
     - Adding them can't move a number, but pure-R tests that pair a default forcing with params naming another index would start to stop.
   - **`h_ml`'s upper truncation**, now characterised:
     - The substep cap stops `h_ml` at 75.02 m at the mode; the P8 geometry wall is at 75.14 m. Raising the cap would gain ≤ 0.12 m.
     - DESIGN.md (substep bullet) already says so. Nothing to decide unless a card should say it.
   - ~~`ccx_nuclear_c14_annual()` only warns~~: **DONE** (§1, j).
5. **If the map is ever rebuilt:** re-run `diag_cmap_posterior_spread.R --n=100` (~45 min, one core), then `promote_cmap_stability.R`. Otherwise the takeaway disappears.
   - A frozen worktree no longer needs `data-raw/downloads` linked for this; the nuclear source is in `data/`. Keep linking for SUITES, so the raw-provenance tests run.

## 4. Non-obvious state

- **`~/ccx_frozen/`:**
  - No worktrees remain.
  - The `.sh` / `.out` / `.pid` files of every past job are still there (54 entries).
  - `20261013_mcmc_hilda31w_smoke_chains/` (96 KB, README) holds the 10-13 smoke-test chains. They were never landed in main; removable on Marcus's word.
- **Preview :7790** (`ccx-app-7790`) is still running, started before `ea29022`. Bit-identical, so it shows the same numbers; restart it to exercise the new loader in the browser.
  - The new loader was checked headless instead: `app/global.R` sources with no nuclear warning, and the forcing sum is 13978.29 mol, equal to the pre-change log.
- **Scratch only:**
  - the copy-facts script;
  - the before/after forcing snapshots (`nuc_before.rds` / `nuc_after.rds`);
  - the mutation-test backups.

  All are in this session's scratchpad, and their results are recorded in CHANGELOG (g), (j). The deploy-gap script IS committed.
- **Still Marcus's (unchanged from 10-14b):**
  - the merged remote branch `origin/claude/recursing-hermann-a2f965`;
  - the flux-trace default;
  - the app never SHOWING `retried` / `converged`;
  - the copy worklist and deploy items;
  - card 4's two by-design failures;
  - the CarboTope `.docx` files;
  - the app's own `.claude/worktrees/compassionate-chatelet-52df58`.
