# Handoff — 2026-09-11 (c). **`hilda31s` IS CANONICAL — the HILDA space with the SEASONAL MIXED LAYER ON, refitted under corrected observables (a round-6 "refutation" turned out to be an artifact of how a seasonal box's concentration was read). FIRST TASK NEXT SESSION: A FULL MODEL EVALUATION of `hilda31s` against the pedagogical standard — every gate, the chain, the assessment note, the blocker list — before any new mechanism is built.**

> Self-contained. Read CHANGELOG **2026-09-11 (3) → (8)** for every number. Memory (Read the sub-index first —
> `INDEX_ccx.md`, now 9 KB with a LIVE STATE block): [[ccx_hilda31s_adopted]], [[ccx_round6b_result]],
> [[seasonal_box_observable_artefact]], [[ccx_option_b_rulings]], [[ccx_assessment_20260908]] (the LAST full
> evaluation, at `hilda31`), [[ccx_scorecard_20260908]]. Previous handoffs today: `handoff_2026-09-11_round6_closed_open_b.md`
> (the morning's start), `handoff_2026-09-11b_observable_artefact_round6b.md` (+ its post-script).

---

## 1. WHAT THIS SESSION DID (commits `4d816b3` … `185c9bf`, CarbonCycleEmulator; `7832847` FaIRtoFrEDI)
| step | outcome |
|---|---|
| suite first | 13,010/402: the pre-existing pair + `test-mode-struct-lint` → three 09-11 files converted to `ccx_mode_base()` |
| option B rulings 1–6 (Marcus) | `ml_hi` = the HS box (57.14°, NOT 40°); Niño3.4 LIMB on `ml_lo` first; `ml_lo` fitted SST sines, `ml_hi` `seas_ml` + PINNED SST amp; `ent_seas_amp_SH` fitted; GATE S re-cut 57–90 °S for `ml_hi`; `h_hs` under the HS Holte prior (09-08d idiom) |
| data | poleward Holte MLD shapes + per-cap ERSST SST amps built; every shipped row bit-identical |
| B build | R side of `seas_ml = 2` written, UNREACHABLE (parser refuses 2); C++/parser/prior/tests NOT built |
| ⛔ FOUND | the gradient row read INSTANT carbon / ANNUAL-MEAN mass → round 6's P7 "302 → 385" was 157 µmol/kg of artifact; its δ¹³C half was the deep compensating; round 6 was FITTED against it |
| RULED (Marcus) | "annual mean of the concentration" → `ccx_box_annual_conc()` (per hemisphere, mass at the time, fixed weights), priced −0.0957 at `hilda31p`, files restamped WITH history (`restamp_mode_objective.R`), 15-test guard mutation-tested |
| round 6b | Torch 17367892 + 17379055: mode **−1475.4579** (h_ml 64.8), second basin −1475.8811 (49.8); likelihood EQUAL to `hilda31p` (−0.61 / +0.23), priors +5.8, **P7 PASS**, P2 inside 2σ, P12 1.25× |
| RULED (Marcus) | **"Promote 1 and clean memory"** → promoted (5 gates), Hessian PD cond 3.4e5 NOTHING step-unstable, repointed; `hilda31p` = `CCX_MODE_SEASML0_CONTROL`; `INDEX_ccx` split → `INDEX_ccx_arch_modes` |
| suite last | **13,044 / 407: 2 failed, 1 error, 3 skipped** — GATE Q at the canonical (deliberately red) + the 08-30 migration error |

## 2. ⭐ THE FIRST TASK: A FULL MODEL EVALUATION OF `hilda31s` (Marcus, closing this session)
The last full evaluation was 09-08f at `hilda31` ([[ccx_assessment_20260908]]: "NOT YET ACCEPTABLE — the ENSO
ocean sign is the broken link; options A–J ranked"). Since then: the periodic spinup (09-09x), the 09-09 rulings,
`hilda31p`, the observable fix, and now the seasonal mixed layer in the shipped model. Nothing has re-read the
WHOLE model since. Do that before building anything. Concretely, in this order:

1. **The scorecard, like-for-like at three arms** — `calibration/diag_whole_model_scorecard.R`. ⚠ Its arm list is
   HARDCODED to the 09-08 state (arm A = `ent26` column control by path; arm B = `SC_HILDA_DIR` = the round-3 dir;
   arm C = the canonical). Re-point arm B to **`hilda31p` by name** (`CCX_MODE_SEASML0_CONTROL`, resolve through
   `dg_vector()`), keep arm A (the column control), arm C = `hilda31s`. Every gate the ledger keeps (V, H, 5, G, Q,
   7, S, 12 as a comparison, L as a comparison, GL, **P7**), the ENSO ocean slope (full + solubility-only, the
   09-04g estimator), the Joos IRF, the likelihood by stream GROUP, the strained priors. Output to
   `outputs/diagnostics/whole_model_scorecard_<date>.{rds,log}`. ⚠ GATE G and the HS-surface row now read
   annual means — the scorecard's own GATE G call goes through `dg_gateG()`, which was converted; check nothing
   else in the scorecard divides box carbon by a mean mass ([[seasonal_box_observable_artefact]]).
2. **The gate ledger, every entry, at `hilda31s`** — `INDEX_ccx_gates.md` is the ledger; update each verdict
   line with the new number and whether it moved vs `hilda31p` (most will not — the mechanism was
   likelihood-neutral; GATE Q is expected red, 6.38 vs 3 × 2.42).
3. **The chain read, against the standard** (Marcus 09-03, `notes/assessment_2026-09-04_public_readiness.md` §0;
   [[ccx_pedagogical_not_emulator]]): seasonal cycle, hemispheric differences, isotopes, physical intuition; driven
   by emissions, ENSO, volcanic aerosol, GMST. For each link: does the model teach the RIGHT physics? The new
   link — the seasonal mixed layer entraining real water — needs its own paragraph: what a reader sees in the
   SPO/MLO seasonal cycles, in the ML DIC cycle (now ±40 µmol/kg), in the surface δ¹³C; and whether `ent_seas_amp_SH`
   at 8.16 (1.25× center) is still a shim the reader would be told about.
4. **The blocker list** — is the ENSO ocean sign still wrong-signed and canceled (r −0.43 at `ent26`; measure at
   `hilda31s`, `gamma_enso_ocn_SH` halved to 0.045)? `rep_dC` +3.11? `q10` −2.11, `kz_deep_frac` −2.38,
   `pump_hs_gcm2` +2.39? The σ-audit's three open items (`INDEX_ccx`)?
5. **Write `notes/assessment_2026-09-1x_hilda31s.md`** in the 09-08 five-line form (verdict; what the arc taught;
   options ranked by payoff to the CHAIN per unit cost, each with the test that decides it; what is acceptable
   as-is) — and re-rank the 09-08f options A–J in light of: **C is DONE** (the seasonal ML), **A/B** (Fix B's limb /
   tropical box) are now option B's rulings 1–2, **P7′ is no longer B's motivation**. Then CHANGELOG + a memory
   file `ccx_assessment_2026091x` + the `INDEX_ccx` live line. Adopt NOTHING in that session.

## 3. FILES — what is where
- **Canonical**: `calibration/output/refit_20260911_hilda31_seasml1/mode_fit_pumpN.rds` (+ `hessian.log`, the
  promote log beside the multistart). Registry `R/paths.R`: `CCX_MODE_CANONICAL = "hilda31s"`, `CCX_MODE_FILES`
  = hilda31s + hilda31p (both free), `CCX_MODE_SEASML0_CONTROL = "hilda31p"`. Column control by path unchanged.
- **Observables**: `R/likelihood.R` `ccx_epoch_year_samples`, `ccx_box_mass_at`, `ccx_box_annual_conc`;
  `ccx_model_ocean_gradient` / `ccx_model_hs_surface` rewritten; `dg_gateG` final-year mean.
  Guard `tests/testthat/test-seasonal-box-observable.R`. Restamp tool `calibration/restamp_mode_objective.R`
  (gates on the PRICED likelihood move; `objective_history` inside the file).
- **Round 6b**: `calibration/output/multistart_20260911_round6b_seasml1_sd1.0452/` (starts, ckpts, logs,
  `collect_round2.log`, `round6b_read.log`, `round6b_p7.log`, `summary.csv`). Diags `diag_round6b_read.R`,
  `diag_round6b_p7_gradient.R`, `diag_seasonal_box_observable_artefact.R`.
- **Option B (paused)**: `R/model.R` (`ccx_mld_shape(box)`, `ccx_seas_ml_ls_on/hs_on`, `ccx_seas_ml_hs_guard`,
  the HS block's time-varying geometry + entrainment limbs); data `obs_mld.rds` `seasonal_hs/so/40_57`,
  `obs_so_sst_seas_amp.rds` `caps`; prereg `notes/prereg_2026-09-11_option_b_ml_box.md` §2a–2c.
- **Torch**: `multistart.sbatch` outdir = round 6b; `make_bundle.sh` ships both refit dirs; `port_targets.csv`
  at `seas_ml = 1` measured against `hilda31p`; queue EMPTY; nothing in flight.
- **Memory**: NEW `INDEX_ccx_arch_modes.md` (registered in `FaIRtoFrEDI/CLAUDE.md`); root routes to `hilda31s`;
  snapshot `../memory_backup_20260911/`. Over SOFT (under hard): `INDEX_cmp_pulse` 17.1 KB, `INDEX_slr` 15.1,
  `INDEX_diag` 15.1, `INDEX_ais` 15.0, `INDEX_ccx_arch` 14.6 — `_cmp_pulse` first when convenient.

## 4. NON-OBVIOUS STATE
- ⚠ **`ccx_mode_file()` is now the ON arm.** Any ON-vs-OFF comparison takes the OFF arm by
  `CCX_MODE_SEASML0_CONTROL`; a diagnostic that builds "the seasonal arm" by setting `seas_ml = 1` on the
  canonical compares ON with ON and feels nothing (test-seas-ml-label's own trap, fixed 09-11 (8)).
- ⚠ **Every stored logpost older than 09-11 (5) is in another objective's units** — the annual-mean read moved
  the canonical family by −0.096; `hilda31p`/`hilda31` were restamped (history inside), the 09-10 round-6 start
  files were NOT (they are the artifact record). Compare on likelihood or re-score.
- ⚠ **The next Torch array needs its reference set re-ruled** — the driver's references are `hilda31p`/`hilda31`;
  add `hilda31s`; regenerate `port_targets.csv` at the array's `seas_ml` (`CCX_MS_STRUCT=hilda CCX_MS_SEAS_ML=<v>
  Rscript calibration/make_port_targets.R`); at `seas_ml = 1` the P8 wall (h_ml ≈ 75–76 m) still makes some
  references infeasible — see [[ccx_seas_ml_p8_wall_blocks_reference_set]].
- ⚠ `refit_20260910_hilda31_periodic/…_hess.rds` records the PRE-restamp logpost as its reference (provenance
  note only). GATE Q (`test-alpha-as`) is red at the canonical by design; `test-seas-lag-split:199` is the
  08-30 migration error (pre-existing, 2 params unencodable).
- `h_ml` 64.8 m sits 10 m under the P8 wall with σ 2.3 m — fine for the mode; a POSTERIOR sample would hit it.
- `ent_seas_amp_SH` 8.16 is still fitted and still a pCO₂-side shim (moves no carbon).

## 5. ⛔ WHAT I WOULD NOT DO
- Build option B (or anything) before the full evaluation — the 09-08f options were ranked against a model that
  has since changed in three ways.
- Quote any 09-10 round-6 number as a property of the seasonal mixed layer.
- Read a seasonal box's concentration at an instant, or over its annual-mean mass, anywhere — audit before a refit.
- Launch an array with the old reference set or a `port_targets.csv` measured at the other `seas_ml`.
