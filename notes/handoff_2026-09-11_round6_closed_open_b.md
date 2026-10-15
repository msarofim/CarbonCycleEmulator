# Handoff — 2026-09-11. **THE ROUND-6 ARC IS CLOSED: the seasonal mixed layer (`seas_ml = 1`) was refitted on Torch, converged at −1492.16, and is REFUTED AS BUILT on GATE P7 (it erases the ocean's vertical δ¹³C gradient); the mechanism is RETAINED, `hilda31p` IS CANONICAL, and OPTION B — latitude structure for the mixed layer — IS OPEN with its prereg written and FOUR RULINGS OWED before a line of code.**

> Self-contained: a fresh session should be able to start B from this note + `CLAUDE.md` + the memory
> files named below. Read **CHANGELOG 2026-09-11 (2)** back to **2026-09-10 (6)** for every number's derivation.
> Memory: [[ccx_round6_result]], [[ccx_hilda31p_adopted]], [[ccx_seas_ml_p8_wall_blocks_reference_set]],
> [[penalty_must_lose_to_the_start]], [[ccx_fixB_reservoir_priced]], [[memory_budget_is_content_not_file]].

---

## 1. WHAT THIS SESSION WAS WORKING ON (09-10 → 09-11, sixteen commits `fa0e7cf`…`86e7907`)
It started from `handoff_2026-09-10_adopt_then_round6.md`, which owed four steps in order — Hessian →
repoint → `seas_ml` capability → the round-6 refit — and ended one ruling past the fourth.

| step | outcome |
|---|---|
| 1. Hessian at the promoted 09-10 mode | ✅ PD, cond 3.6e5, `h_ml` unstable (same flag as `hilda31`) |
| 2. Repoint | ✅ `hilda31p` canonical, `hilda31` quarantined; mode files now record `seas_ml` **and `spinup`** |
| 3. `seas_ml` capability | ✅ read, RECORDED, GATED; driver and port targets REFUSE an unset label var |
| — memory clean (Marcus) | ✅ root NOT over its ceiling (13.1 KB content; the "19 KB" was `wc -c` — 4th time); stale facts fixed; 0 orphans / 0 dangling |
| — `test-mode-file.R:187` | ✅ option 2 (Marcus): free arms RE-SCORED on today's objective |
| 4. Round 6 refit | ✅ ran (24 + 3 requeued + 14 round-2), converged −1492.1591 |
| — its read | ✅ likelihood −17.8 vs `hilda31p`, ALL on the two gradient rows; **GATE P7 FAILS at 2×** |
| — the ruling (Marcus) | ✅ refuted as built, mechanism retained, arc closed, **B next** |

## 2. DECISIONS MADE, AND WHY (each one Marcus's unless marked "mine")
1. **`hilda31p` replaced `hilda31` as canonical** (09-10 handoff step 2; executed by hand — `run_post_refit_adoption.R`
   is hardcoded to the 08-28 arc). Why the quarantine had to come FIRST: `test-mode-file.R:187` picked the free arm
   with the largest STORED logpost, and `hilda31`'s −1478.66 (aseasonal units) beats `hilda31p`'s −1480.54 (periodic
   units) on paper while being 9.09 BEHIND like-for-like.
2. **`seas_ml` is the second axis of the objective label, beside `struct`** (mine, implementing the handoff): routed
   through `ccx_apply_structure(p, struct, seas_ml)` so every base-list builder carries it; the DRIVER and
   `make_port_targets.R` STOP on an unset `CCX_MS_STRUCT` or `CCX_MS_SEAS_ML` — an unset default is exactly how the
   09-10 refit ran the wrong arm unnoticed.
3. **Mode files record their spinup vintage** (mine): `spinup = "periodic"|"aseasonal"`, read by `ccx_mode_spinup()`;
   `hilda31p` was stamped AFTER proving its logpost reproduces under periodic (0.0) and not aseasonal (−6.67).
4. **The round-6 reference set** (Marcus: "follow the recommendation"): at `seas_ml = 1` the P8 guard makes the
   objective −Inf above h_ml ≈ 75 m, and the 08-31e new-basin reference (144 m) and the whole 09-10 second basin
   (164 m) sit there. References := `hilda31p` + `hilda31` (by path); `CCX_MS_SPREAD` set EXPLICITLY to 1.0452
   (their measured separation is 0.0993, a tenth of it) and named in the outdir.
5. **The infeasible-step penalty is derived from the start, 10×|start|** (mine, forced by a defect mid-array): a
   fixed 1e6 is a BASIN for any start worse than −1e6 — three tasks "CONVERGED" onto it in 2.5 min, passed the
   ordering gate, exited 0. Fixed + a dead-task gate + the collector refuses dead files; requeued from a SEPARATE
   tree because 21 tasks were reading the old driver.
6. **`test-mode-file.R:187`, option 2** (Marcus): re-score every free arm's `par_mode` under today's objective and
   require the canonical to win on THAT; the comment and the assertion now agree.
7. **Round 6 refuted as built, mechanism retained; B next** (Marcus, on my recommendation). The decisive read is
   **GATE P7**: the modern surface−deep δ¹³C gradient −0.309 → **+0.018** (target −0.861), DIC 302 → **385** (233)
   — the seasonal ML homogenizes the isotope gradient and steepens the DIC one, both away from obs. Pedagogically
   that is a broken link (a reader takes away the wrong physics). What it bought: priors +6.2, P2 relaxed
   (z −2.89 → −2.07, NOT inside 2σ), P12 half (`ent_seas_amp_SH` 18.7 → 9.5, 1.45× center). Hypothesis (mine, in the
   prereg): ONE cause for P7 and the ENSO sign — the ML has no latitude structure (P1c: an 84 %-subtropical box
   given the hemispheric MLD cycle); the same split that gives `seas_ml` a high-latitude box gives Fix B its
   tropical one. Hence B before E.

## 3. FILES — created / touched / pending
**Model + harness (`R/`, `calibration/`)**
- `R/calibrate.R` — `ccx_apply_structure(p, struct, seas_ml)`, `ccx_parse_seas_ml()`.
- `R/paths.R` — `CCX_MODE_CANONICAL = "hilda31p"`, `hilda31` in `CCX_MODE_RETIRED`, `CCX_MODE_HILDA31_QUARANTINED`,
  `ccx_mode_seas_ml()`, `ccx_mode_spinup()`, `ccx_mode_base()` carries both.
- `R/periodic_spinup.R` — `ccx_spinup_label()`, `ccx_spinup_from_label()`.
- `calibration/run_dispersed_multistart.R` — label vars REQUIRED; `seas_ml` recorded + gated; references
  `hilda31p`/`hilda31` via the registry; `MS_PENALTY = max(1e6, 10×|start|)`; dead-task gate; outdir default names
  `hilda31p_periodic` (+`_seasml1`).
- `calibration/make_port_targets.R` — label vars REQUIRED; `seas_ml` column; refuses a non-finite target.
- `calibration/promote_multistart_mode.R` — records `seas_ml` and `spinup`.
- `calibration/collect_dispersed_multistart.R` — excludes dead files.
- `calibration/torch/multistart.sbatch`, `setup_torch.sh`, `make_bundle.sh` — `CCX_MS_SEAS_ML` (default 1),
  `CCX_MS_SPREAD` (1.0452), outdir `multistart_20260910_round6_seasml${SEAS_ML}_sd${SPREAD}`; bundle ships the two
  reference modes. `calibration/torch/port_targets.csv` — **at `seas_ml = 1`** (see §5).
- NEW: `calibration/stamp_mode_spinup.R`, `calibration/diag_round6_read.R`, `calibration/diag_round6_p7_gradient.R`;
  `calibration/lib_design_gates.R` — **GATE P7** (`DG_LEDGER` + `dg_gateP7_verdict()`).
**Tests** — NEW `test-seas-ml-label.R` (67), `test-gate-p7.R` (18); REWRITTEN `test-enso-demean.R` PRICED → canonical
price 45.1896 + `hilda31` ratification pin 43.8367/63.7282; `test-mode-file.R` option 2.
**Outputs** — `refit_20260910_hilda31_periodic/` (+ Hessian block, `_hess.rds`, log, `spinup` stamp);
`quarantine/20260910_periodic_spinup_adopted/refit_20260908_hilda31/` (+ README);
`multistart_20260910_round6_seasml1_sd1.0452/` (24 starts, ckpts, `collect_round{1,2}.log`, `round6_read.log`,
`round6_p7.log`, `logs/`). Mode −1492.1591 = `start_004.rds`. **Not promoted, not to be.**
**Notes** — `notes/handoff_2026-09-10b_seasml_wall.md`, `notes/prereg_2026-09-11_option_b_ml_box.md`, this file.
CHANGELOG: 2026-09-10 (6), (7); 2026-09-11, (2).
**Memory** — NEW `ccx_hilda31p_adopted`, `ccx_seas_ml_p8_wall_blocks_reference_set`, `penalty_must_lose_to_the_start`,
`ccx_round6_result`; UPDATED `ccx_hilda31_adopted` (superseded), `ccx_refit_ran_at_seas_ml_0`,
`port_targets_need_the_struct_var` (closed structurally), `memory_budget_is_content_not_file` (4th occurrence);
indexes `INDEX_ccx`, `INDEX_ccx_seas_ml` (now archive-bound), `INDEX_ccx_gates`, `INDEX_ccx_seas_mech`, `INDEX_diag`,
root `MEMORY.md` (header list 20 → 27 sub-indexes; the "check with `wc -c`" line replaced).
**Pending** — none in flight. Torch: nothing queued; the temporary `CarbonCycleEmulator_r6fix` tree is removed.

## 4. THE OPEN QUESTION / NEXT STEP: OPTION B, and the four rulings before it
`notes/prereg_2026-09-11_option_b_ml_box.md` is the design note. Per hemisphere: `ml_lo` (tropics + subtropics,
~84 % of area, thermal seasonal regime, Fix B's ~26 Sv Niño-modulated upwelling limb) and `ml_hi` (poleward of
~40°, ~16 %, `seas_ml` ON with a POLEWARD MLD climatology). Deep column, K(z), HS/HD, pump untouched.
**Rulings owed (ask, do not assume):** (1) is `ml_hi` the existing HS box or a new box; (2) tropical box or limb on
`ml_lo`; (3) which seasonal driver each box gets / does the sine path retire; (4) does `ent_seas_amp_SH` survive.
**Data task:** a poleward-masked Holte MLD climatology (`data-raw/build_mld_targets.R` builds the hemispheric one).
**Preregistered (sign + bound written before any run):** **P7′** — `seas_ml = 1` on `ml_hi` PASSES GATE P7 (if not,
the entrainment formulation is wrong: STOP); **PB1** — solubility-only ENSO r flips positive at a physical
modulation and `gamma_enso_*` |sum| 0.356 → < 0.18; **PB2** — two SH regimes, GATE S still passes on `ml_hi`;
**PB3** — P2 inside 2σ, `ent` ≤ 1.5× center or retired; **PB4** — Δ¹⁴C rows < 1 log-unit each; **PB5** — no loss on
likelihood vs `hilda31p`; **PB6** — CO₂ seasonal rows < 1.
**First thing in the B session:** re-run the FULL suite (`stop_on_failure = FALSE`; read `failed` AND `error`) — the
last full run (12,990 / 2 / 1 / 4, the pre-existing pair) predates `test-gate-p7.R`, the option-2 rewrite and the
P7 ledger entry, each green alone.

## 5. NON-OBVIOUS STATE
- ⚠ **`port_targets.csv` is at `seas_ml = 1`.** Any `seas_ml = 0` array needs
  `CCX_MS_STRUCT=hilda CCX_MS_SEAS_ML=0 Rscript calibration/make_port_targets.R` first, or the port gate refuses (correctly).
- ⚠ **`seas_ml = 1` has a HARD WALL at h_ml ≈ 75 m** (P8 guard → −Inf, finite at 74, −6.4e8 at 75). The cold init
  (h_ml 75.0) sits ON it. Feasible references + the derived penalty are what make an array survivable.
- ⚠ **Every stored logpost before 09-10 is in another objective's units** (prior re-centering 09-09w −0.811; spinup
  adoption 09-09x −10.16 at `hilda31`). Compare on likelihood or re-score. `hilda31p` unrefitted at `seas_ml = 1` is
  −1634.68 (−154) and is NOT evidence about the mechanism.
- ⚠ **`rep_dC` +3.17** — the worst strain in the model, untouched by every ocean option and not B's job. Owed.
- ⚠ **Torch**: `cs` not `cpu_short`; ship a bundle only with `squeue` empty (or to a separate tree); the startup
  s/eval is inflated 24-wide and shortened several first restarts (cosmetic); `seas_ml = 1` costs ≈1.2× on the nodes
  (0.71–1.07 s/eval), not the 3× feared.
- ⚠ **Memory budgets are CONTENT bytes**, never `wc -c` on the root (its header is ~6 KB). Root 13.2 KB content
  (soft 12.3, hard 18.4). `INDEX_slr` 17.6, `INDEX_cmp` 17.2, `INDEX_cmp_pulse` 17.1 KB — over soft, under hard;
  split when convenient (split line stated in both files, orphan sweep after).
- `INDEX_ccx_seas_ml.md` is now archive-bound; B's live state goes in `INDEX_ccx` / `INDEX_ccx_ocean_struct`.

## 6. ⛔ WHAT I WOULD NOT DO
- Promote the round-6 mode, or describe it as anything but "refuted on P7, mechanism retained".
- Build B without the four rulings, or build `ml_hi` fresh before checking whether the HS box IS it.
- Run any array with `CCX_MS_SEAS_ML` not matching the CSV; ship a bundle over a running array.
- Trust a "root MEMORY.md is over budget" claim that came from `wc -c`.
