# PREREG 2026-08-27n — **THE SH CANCELLATION ARM: `seas_T_amp_SH`**
# Written and committed BEFORE `calibration/diag_seas_T_amp_sh_power.R` exists. No gate may move.

**Hypothesis (27m).** The model's SH land seasonal signal at SPO is 1.92× the observed **not because
its productivity is too big, but because too little of it is CANCELED.** CT2022 says SH land nets
only **25.1 %** of its gross productivity swing to the atmosphere (NH: 68.2 %). The model's
canceling channel is soil respiration, scaled by **`seas_T_amp_SH`**, which the fit has driven to
**1.0391 K = 28.9 % of the LOW end** of its measured bracket [3.5915, 7.1012] — while cranking
`seas_T_amp_NH` to **131 % of its HIGH end**. [[seas_amps_hemispheric_inversion]]

---

## 1. THE PRE-CHECK — WHAT IS ALREADY MEASURED, AND WHAT IS NOT

⚠ **BOUNDARY.** Everything in this section is a measurement of **channels that already exist at the
incumbent mode**, from the existing `calibration/diag_seas_signature_inversion.R` plus closed-form
arithmetic. **No arm has been run and no parameter has been re-optimized.** The gates in sec.3 are
predictions about a run that has not happened. This mirrors 27h, whose pre-check *killed* its test
before a prereg was written; this one survives its pre-check, which is why this file exists.

**The two SH land channels at SPO, as the model currently carries them** (`base − channel-off`, so
signed contributions; `diag_seas_signature_inversion.R` sec.1):

| channel | p2p, ppm | peak month |
|---|---|---|
| SH NEP (`seas_npp_amp_SH`) | **1.3950** | 10.15 |
| SH respiration (`seas_T_amp_SH`) | **0.0926** | 5.05 |

**They are 153° apart — near-antiphase, so respiration CANCELS, and the lever has the SIGN.**
Vector sum = **1.313 ppm @ month 10.09**, which reproduces handoff 27k's independently-computed
SH-local land of **1.315 @ 10.09**. That agreement is the arithmetic's own validation.

**REACH.** The respiration channel is **linear** in `seas_T_amp_SH` (the q10 exponent is only
±0.0132 at the mode, deep in the linear regime), so the whole profile is closed-form:

| | `seas_T_amp_SH` | net SH-local land | vs obs 0.683 | excess closed |
|---|---|---|---|---|
| **landed** | 1.039 | **1.313** | 1.92× | 0 % |
| bracket LO | 3.592 | 1.119 | 1.64× | 30.8 % |
| prior init | 5.050 | 1.015 | 1.49× | 47.4 % |
| **bracket HI** | 7.101 | **0.879** | **1.29×** | **68.8 %** |

**AND THE PRIOR PAYS YOU TO DO IT: +8.34 log-units** from landed to bracket HI (logprior −10.640 →
−2.303). **Contrast `seas_npp_amp_SH`, which COST 79 conditionally and needed a value the provenance
forbids** ([[land_and_ocean_are_one_fix]]). This lever moves **toward** its measured bracket, not out
of it.

⚠ **BUT THERE IS A HARD GEOMETRIC FLOOR, AND IT IS THE MOST IMPORTANT NUMBER HERE.** Because the two
channels are 153° apart and not 180°, the net magnitude is bounded below by the perpendicular
component: **min net = 1.3950 · sin(27°) = 0.633 ppm, at `seas_T_amp_SH` = 13.95 K.** Beyond that the
net **rises again**. The observed 0.683 sits *just* above this floor and needs **11.08 K = 1.56× the
bracket HI**.

**⇒ THE LEVER CANNOT CLOSE THE GAP INSIDE ITS OWN OBSERVED BRACKET. It closes 69 % of it.** This
prereg is therefore a test of a **partial** mechanism, and says so before it is run. Any write-up
that later reports "the cancellation hypothesis is confirmed" without the residual 1.29× is
misreporting it.

## 2. DESIGN — TWO STAGES, AND STAGE 1 IS A FALSIFIABLE ARITHMETIC CHECK

**STAGE 1 — FROZEN PROFILE.** Only `seas_T_amp_SH` moves; all 21 calibrated parameters held at the
mode. Grid = the **MEASURED bracket plus the two geometry points**:
`{1.0391 (landed), 3.5915 (LO), 5.0503 (prior init), 7.1012 (HI), 11.08 (reaches obs), 13.95 (floor)}`.
⚠ **The last two are OUTSIDE the observed bracket and are reported FOR THE GEOMETRY ONLY — they are
not proposed values.** [[threshold_from_obs_or_law]]

**STAGE 2 — CONDITIONAL REFIT.** The whole 8-parameter seasonal slice re-optimized at each fixed
`seas_T_amp_SH`, continuation warm-start + BFGS polish + restart-until-still, **with restart count
and last gain PRINTED**. ⚠ An under-converged optimum at a fixed parameter OVERSTATES that
parameter's cost and manufactures an "unaffordable" verdict — 27h's first conditional run hit `maxit`
at all three points and was discarded. **Never accept a silent `maxit`.**

## 3. THE GATES — PREDICTIONS, FIXED NOW

**Stage 1 (frozen) — these are arithmetic and the tolerance is tight:**

- **P0 · IDENTITY.** At `seas_T_amp_SH` = 1.0391 the run reproduces the incumbent SH-local land to
  **within 0.5 %** and the logpost to **< 0.05**. A zero-perturbation control. [[apply_sanity_tests]]
- **P1 · SIGN + MAGNITUDE.** Net SH-local land = **1.313 / 1.119 / 1.015 / 0.879** at the four
  in-bracket points, each **within 3 %**. This tests the linearity assumption AND the two-channel
  decomposition at once. **A miss here falsifies the closed-form pre-check, not the hypothesis.**
- **P2 · THE FLOOR IS REAL.** Net SH-local land is **NON-MONOTONE**: it reaches a minimum of
  **0.633 ± 0.02 ppm near 13.95 K** and is **higher at 20 K than at 13.95 K**. A strong structural
  prediction that only the 153° geometry makes. **If the profile is monotone to 20 K, the
  two-channel picture is wrong.**
- **P3 · PRIOR ARITHMETIC.** logprior improves by **+8.34 ± 0.05** from 1.0391 → 7.1012. Pure
  arithmetic; a miss means the prior was misread.

**Stage 2 (conditional) — these are the real test and they are riskier:**

- **P4 · THE PRICE IS NOT PROHIBITIVE.** Conditional Δlogpost at `seas_T_amp_SH` = 7.1012 is
  **> −20** relative to the incumbent. **PREDICTED POSITIVE**, since the prior alone pays +8.34 and
  the SPO land overshoot should improve. ⚠ **This is the risky one.** A large negative says some
  likelihood row objects and the hypothesis is in trouble regardless of the geometry.
- **P5 · WHICH ROW PAYS — the diagnostic gate.** `co2_seasonal_SPO` **IMPROVES** (Δ > 0). This is
  the exact opposite of 27i, where that single row carried **−113.25 of −113.87** and killed the
  productivity lever because it was **already matched and could only punish a driver that moves**
  ([[seas_right_observable_wrong_drivers]]). **If it punishes here too, the SPO CO2 row is vetoing
  ANY change to SH land and the arc's whole framing needs re-examining, not just this lever.**
- **P6 · NO COMPENSATING COLLAPSE.** `sst_seas_amp_SH` stays **within 2σ of its landed 0.3596**.
  27j's LAND-only arm saw it collapse to **0.176 (z −9.18)** to absorb the change; a repeat means the
  arm is being paid for elsewhere and the reported land improvement is not real.
  [[ent_channel_counterweight]]
- **P7 · PARTITION.** SPO δ¹³C-per-ppm moves **from 1.940 toward 1.0** (i.e. **< 1.85**).
- **P8 · THE RESIDUAL IS DECLARED.** Report the residual multiple of observed at the best in-bracket
  point. **Predicted 1.29×.** Reporting a "confirmed" verdict without this number is a fail.

## 4. WHAT WOULD FALSIFY THE HYPOTHESIS

- **P1 fails** ⇒ the closed-form pre-check is wrong; re-derive before running Stage 2.
- **P2 fails (monotone profile)** ⇒ the near-antiphase two-channel picture is wrong.
- **P4 strongly negative or P5 punishes** ⇒ cancellation is not affordable, and the SH land overshoot
  is NOT a respiration-amplitude problem. Next suspects would be the **0.9-month phase error**
  (the channels should be 180° apart and are 153°) or the SPO **weighting** — the exact mirror of
  [[sh_ocean_weighting_not_phase]] on the ocean side.
- **P6 fails** ⇒ the improvement is bought, not earned.

## 5. ⚠ THE CLOSURE ARM — SECOND STAGE, AND IT NEEDS A DECISION FIRST

27m left an arithmetic that closes the whole story and it should be recorded **before** it is tested,
so it cannot be back-fitted:

    CMIP6 says the SH productivity amplitude should be ~1.87x bigger  ->  A_nep = 1.395 x 1.87 = 2.61
    CT2022 says SH land nets only 0.251 of its gross               ->  net = 2.61 x 0.251 = 0.655
    OBSERVED SH-local land at SPO                                                        = 0.683

**Two products, neither fitted to this quantity, predict it to 4 %.** ⇒ **C1: with
`seas_npp_amp_SH` raised to CMIP6's 0.94 AND `seas_T_amp_SH` free, the fit should land
`seas_T_amp_SH` INSIDE its observed bracket and net SH-local land within 15 % of 0.683.**

⚠ **NOT AUTHORIZED YET.** It changes `SEAS_NPP_AMP_SH` to a **CMIP6 ensemble** value — models, not
observation — and that is Marcus's call, exactly as the GPP end was. **Do not run C1 until it is
made.** ⚠ And the ratio transfer is an **approximation**: 0.251 is a hemispheric FLUX ratio and the
SPO signature is a particular weighting of it, so the 4 % agreement must not be quoted as an identity.

## 6. TRAPS THAT WILL BITE THE DRIVER (from 27k sec.5 + today)

- **`md$u_mode` — spell it out.** R's `$` partial-matches, so `md$u` silently resolves to `md$u_mode`.
  Today that worked; it is one added field from resolving to something else.
- **SEVEN calibrated names are likelihood-side and absent from `ccx_default_params()`** —
  `bomb_total`, `luc_scale`, `sigma_d14c`, `rep_dC`, `grad_off_co2`, `grad_off_d13c`. Read them off
  `pv` (the `ccx_unc_to_par()` list), never off `p`. `p$bomb_total` is NULL, `NULL/102` is
  `numeric(0)`, and `F$c14_bomb` silently becomes zero-length. **Cost a 12-minute run on 08-27.**
- **`ccx_model_stats()` returns a LIST OF COLUMNS, not a data.frame** — `nrow()` is NULL, `sprintf()`
  returns `character(0)`, `cat()` prints nothing and raises nothing. Use `length()` and gate it.
- **`seas_npp_amp_SH` and `ent_seas_amp_SH` are outside `CCX_PARAM_TABLE`** — anything reading a mode
  gets the constant / 0 unless told otherwise. `seas_T_amp_SH` **IS** in the table (unlike those two),
  so Stage 2 must **remove it from the free set** when profiling, not merely overwrite it.
- **`ccx_make_logpost()` does not reproduce the mode's stored logpost** (−1547.9370 vs −1544.6148,
  offset −3.3223, pre-existing). **Never quote an absolute logpost against the mode file**; matched
  comparisons only. [[ccx_mode_logpost_offset]]
- **Run from a FROZEN COPY in /tmp.** `Rscript` parses incrementally. [[never_edit_a_running_script]]
- **Pin BLAS to one thread and check `uptime` first.** [[eta_in_days_is_not_a_slow_run]]

## 7. PROVENANCE

Mode `calibration/output/refit_20260825f_from90/mode_fit_pumpN.rds` (arm N), `seas_drivers 1`,
`ent_seas_amp_SH = 0`. Channel amplitudes from `diag_seas_signature_inversion.R` at that mode,
2026-08-27. Bracket from `SEAS_T_AMP_SH_OBS_{LO,HI}` in `R/constants.R` (CRU 1961-90 absolute,
CRUTEM5 mask; HI is SH land >30S, ">45S is Antarctica and carries no respiring soil").
Cancellation ratios from `notes/collect_2026-08-27m_...md` sec.4.
