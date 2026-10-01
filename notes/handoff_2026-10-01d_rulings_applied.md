# Handoff 2026-10-01 (d): Marcus's 12 rulings applied. The emissions interpolation is constant, the Laplace band failed and is HELD, the MCMC check is built for Torch, and the B8 assessment is drafted

> **Session start.** Launch from `FaIRtoFrEDI/`, then `change_directory` here (CLAUDE.md). ⛔ Never use a bare
> `cd` in a Bash call; use `git -C` or absolute paths.
>
> **Read first:**
> 1. this file;
> 2. CHANGELOG **2026-10-01 (j), (k), (l), (m)**;
> 3. ⭐ `notes/assessment_2026-10-01_hilda33d_DRAFT.md`: the B8 draft. **Its §5 (verdict) and §7 (the acts) are
>    Marcus's.**
> 4. memory:
>    - `laplace_fails_on_fertilisation_ridge.md` (new);
>    - `ccx_hilda33d_adopted.md` (its 10-01 (j–l) section);
>    - `dollar_partial_matches_on_lists.md` (its second incident);
>    - `ccx_pulse_spline_ringing.md` (the flip is done);
> 5. `notes/review_2026-10-01c_open_decisions.md`. §A and §B are RULED (the banner at its top); §C is still open.

---

## 1. What the rulings did (the mapping is in the review note's banner)

| # | item | what was done | commit |
|---|---|---|---|
| 1 | A1 card 6 | retired; id 6 is a hole the validator refuses to reuse; the lead counts the ledger ("Seven") | `2cee507` |
| 2 | A2 pulse box | "about 1.4 °C per 1000 GtC" at 20/50/100/200 yr; constants re-pinned; the named red discharged | `2cee507` |
| 3 | A3 | the "fertilisation is the only land sink" sentence deleted in all four places | `2cee507` |
| 4 | A4–A7 | card 4 "a little below" Meinen (gated); card 5 the timing; four land pools; N deposition as a driver | `2cee507` |
| 5 | B2 | **BETA v1.0 CarboTope**; `APP_RELEASE_MODE` gated against the loaded mode (`test-app-version.R`) | `2cee507` |
| 6 | B1 | D4 exclusive; "+0.50 GtC/yr retained via N deposition" beside it (re-read after the flip: 67.67, z +1.50) | `2cee507`, `0afefec` |
| 7 | B3/B3b | `ccx_comparable_rows()` in the AIC gate; the parent re-documented | `2cee507` |
| 8 | B4 | `ndep_ret` "Gross carbon uptake per unit of nitrogen deposited on land" | `2cee507` |
| 9 | B5 | the fertilisation switch reworded, CO₂ fertilisation only; Marcus: no separate N switch | `2cee507` |
| 10 | B6 | `CCX_EMIS_METHOD_DEFAULT` "constant"; six files priced and restamped; 10 test re-pins approved | `3d38d56`, `4f5e5db`, `46d96f3` |
| 11 | B7 | Laplace ribbons built → **failed their check → HELD**; MCMC built for Torch, NOT submitted | `c12af28`, `0afefec` |
| 12 | B8 | drafted: `notes/assessment_2026-10-01_hilda33d_DRAFT.md` | this commit |

## 2. ⚠ Things to know before touching anything

- **hilda33d's stored logpost is −1405.411447** (constant interpolation). Anything quoting −1405.249036 is pre-flip.
  The adoption-time scorecard (`whole_model_scorecard_20261001_hilda33d.*`) is pre-flip. The post-flip one is
  `…_hilda33d_emisconst.*` (run from a frozen `git archive`, so it stamps `@?`; the commit is `508b2bf`).
- **No band ships.** `APP_RIBBONS_HOLD` (app/global.R) keeps the app band-free whatever sits in `data/`, and
  `test-futures-ribbons.R` asserts it. Lift it only on a ruling, after the MCMC check. The evidence is
  `outputs/diagnostics/futures_ribbons_laplace_held_20261001.rds`.
- ⛔ **The stored covariance is LOCAL.** Along `beta_max` / `fert_k` / `ndep_ret` the posterior is far narrower or
  more curved than the Gaussian (importance ESS 8/1000). Don't quote 10-01 (a)'s ±39 ppm, or any delta-method
  spread along that ridge, as a posterior spread.
- **Card 7** keeps its approved text, plus ONE drafted sentence ("That has since been measured: …"). The copy is
  Marcus's to reword.
- **Two historical identities run under "spline" on purpose** (`ccx_with_emis_method()`): the D2/D3 screen in
  `test-gated-params` 6, and the 09-19 knock-out in `test-seas-ml-hemi` (5).

## 3. Next steps

1. **The MCMC check on Torch** (Marcus chose Torch; he authenticates, I submit only when asked):
   - `calibration/torch/make_bundle.sh`, then scp, then `setup_torch.sh` if the R library is gone;
   - the SMOKE first:
     `CCX_MC_N=600 CCX_MC_ADAPT=300 CCX_MC_OUT=outputs/mcmc_smoke sbatch --array=1-4 --time=00:45:00 calibration/torch/mcmc_check.sbatch`;
   - read for each chain: the port line (recomputed = stored), exit 0, `chain_<k>.rds`, and the s/iteration (that
     sizes production);
   - production: `CCX_MC_COMMIT=<sha> sbatch --array=1-4 calibration/torch/mcmc_check.sbatch` (cs, 36 h; resubmit the
     same command to resume). At 0.59–1.08 s/eval that is ~16–30 h per chain.
   - Then, still to write: a reader for split R-hat and bulk ESS on the parameters and the ribbon quantities. Pool
     the post-adaptation draws, save them as a u-matrix, and run
     `calibration/build_futures_ribbons.R --draws=<that rds> --out=outputs/mcmc_check/futures_ribbons_mcmc.rds`.
   - ⚠ A curved ridge mixes slowly for a random-walk sampler in u-space. Judge it on R-hat and ESS, not on
     acceptance.
2. **B8:** Marcus's verdict and acts in the draft's §5 / §7. The suite count to quote is in §4 below.
3. **§C of the review list** (13 older items) is untouched. The deploy checklist (both URLs are still placeholders)
   gates any public release.
4. Copy items NOT ruled (review A9), left as they were:
   - the emissions switch's blurb (it now also removes N deposition);
   - the box diagram's N-retention arrow;
   - the imbalance panel's framing;
   - the AOD label in anomaly mode;
   - the verdict phrases printed regardless of the computed value.

## 4. State

- **Suite at the final state (`ca14204`): 5534 passed, 0 failed, 0 errors, 4 skipped.** Frozen copy `~/ccx_frozen/final_ca14204`, which also
  holds the two git-ignored inputs `nuclear14c` and `glodap_c13c14_subset.csv`.
  - At `4f5e5db` (flip + restamp, before the re-pins) it was 5497 / 10 / 0 / 5. The 10 were the approved ledger.
- **Running:** nothing (the app preview was already stopped at session start).
- **Other sessions:**
  - the git-stamp branch `claude/youthful-blackburn-fbc009` is still unmerged and claims CHANGELOG (h). Its lint would
    want `ccx_git_stamp()` in this session's new drivers (`build_futures_ribbons.R`, `run_mcmc_check.R`,
    `diag_emis_constant_price.R`, `diag_d4_readout.R`, `diag_ribbons_linearity.R`, `diag_laplace_axes.R`).
  - the `emissions-interp-constant` branch is SUPERSEDED by 10-01 (k). It can be deleted with Marcus's OK.
- **Disposable:** `~/ccx_frozen/{suite_20261001j, ribbons_trial_20261001, ribbons_c12af28, final_508b2bf}`.
- `carbotopecomment.9.26.26.docx` is Marcus's; leave it. `outputs/diagnostics/smoke/` stays untracked.
- Memory: `INDEX_ccx_app.md` 14,230 B and `INDEX_ccx.md` 14,049 B, both under the 14 KB (14,336 B) soft budget. The root
  `MEMORY.md` is still over its soft budget (pre-existing).
