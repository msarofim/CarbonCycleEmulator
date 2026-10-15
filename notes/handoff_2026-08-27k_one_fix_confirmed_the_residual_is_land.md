# Handoff — CarbonCycleEmulator, 2026-08-27k: **THE PARTITION IS ONE FIX, AND IT IS CONFIRMED**
# The channel works when the land is corrected. What is left is a LAND SIZE error of 1.33×.

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, trunk `main`, **clean**.
**Nothing is running.** **Suite: 1157 pass / 0 fail** (unchanged — `R/` and `src/` were never
touched today). Four commits, `74ad6ed..7364f4c`.

**⚠ TWO DECISIONS ARE OWED (§6), and one of them is not a modeling choice — it is whether the
model may use the GPP end of a 1.4× product disagreement.**

---

## 0. STATE IN EIGHT LINES

1. **Marcus chose 27h fork (a).** It was pre-checked and **killed before it ran** — `tau_ex` has
   neither the price nor the SIGN. §1
2. **The NH import is HIDING the SH-land overshoot, not causing it.** §1
3. **Marcus chose (A): power-check `seas_npp_amp_SH`.** It has the SIGN but costs 79 log-units,
   and the ENTIRE bill is one already-matched row. §2
4. **⇒ The SPO total is right BY CANCELLATION, so land and ocean are ONE fix.** §2
5. **Marcus chose the JOINT arm. Pre-registered `fa83faa`, then run. P1 CONFIRMED: +64.99 against
   a gate of +39.59.** §3
6. **The channel was being SUPPRESSED by the land error** — it reaches 8.11 µmol/kg, inside its
   band for the first time, and rotates the ocean limb 4.13 → 9.24 months. §3
7. **P4 and P5 FAILED, for one reason twice: land is still 1.33× too big.** §4
8. **4b is not ruled out but is no longer indicated.** §6

---

## 1. WHAT HAPPENED TO FORK (a) — `tau_ex`

Collect: `notes/collect_2026-08-27h_tau_ex_has_no_power_and_the_wrong_sign.md`. Commit `1daa92f`.
Two new diagnostics: `calibration/diag_tau_ex_seasonal_power.R` (15-point profile, gradient offsets
re-optimized, ~12 min) and `diag_tau_ex_conditional_power.R` (whole 8-par slice re-optimized at
fixed `tau_ex`, ~35 min).

**The wider slice was NOT run and no prereg was written for it.** Its null was structurally
guaranteed. [[no_power_null]]

- **PRICE.** `tau_ex` is pinned to **~2.6 % per log-unit**. The 27g challenger's entire +11.62 buys
  τ +9.2 %, moving the NH import **0.821 → 0.758 ppm** — 9 % of the ~0.70 ppm excess. The
  conditional slice buys back ~30 % (1.26τ: 77.01 → 53.93) and that point is **bought, not earned**
  (`grad_off_co2` −0.827, past the measured −0.386/−0.549).
- **INVARIANCE.** Over an 8× grid at any price: SPO total −1.7 %, **SH-LOCAL land +1.7 %**, while
  NH-origin falls 73 %.
- **SIGN.** At 4.00τ (−4529 log-units) the inversion's SPO land ratio goes **2.01× → 2.07×,
  WORSE.** NH-origin peaks month 6.47, SH-local land 10.09 — **108° apart, partly CANCELING.**

**This is the second half of 27e**, which exonerated `tau_ex` as a PARTITION lever but was frozen
in the other 20 parameters and called every cost an overstatement. 27h §4 said the binding error is
one of SIZE; this answered it.

**A standing code note now needs qualifying.** `R/likelihood.R:175` — "66 % of `tau_ex`'s leverage
came from the seasonal harmonics" — holds only DOWNWARD. Upward the bill is annual-mean isotopes
and ¹⁴C, and the four seasonal rows net **−3.4 of −77.0** with `co2_seasonal_SPO` actually
**improving +9.74**. **The comment in `R/likelihood.R` has NOT been edited** — see §5.

## 2. WHAT `seas_npp_amp_SH` SAID

Collect: `notes/collect_2026-08-27i_the_land_and_ocean_fix_is_one_fix.md`. Commit `aec9123`.
`calibration/diag_seas_npp_sh_power.R`, ~50 min.

**The grid came from the measurement**, not a chosen span: `R/constants.R` gives PsnNet
**0.5027 ± 0.087** and **GPP 0.352** as the other end (**−1.73 sd**). [[threshold_from_obs_or_law]]

- **SIGN, unlike `tau_ex`:** SH-local land **1.308 (1.92× obs 0.683) → 0.892 (1.31×)** at the GPP
  end — **67 % of the excess.** Partition ratio conditionally **1.940 → 1.834** (⚠ the RAW arm
  moves the OTHER way, 1.930 → 1.950 — the script now prints both).
- **PRICE: 79.01 conditionally, 113.87 raw, and the ENTIRE bill is `co2_seasonal_SPO` (−113.25 of
  −113.87)** while `d13c_seasonal_SPO` **improves +2.99** and every level/gradient row moves ≤ 0.03.
  That CO₂ row is already matched to ~1 %, so it can only punish a driver that moves.
  [[seas_right_observable_wrong_drivers]]

**⇒ The model's SPO total is right BY CANCELLATION — 1.141 vs observed 1.168 — from land 1.92× too
big and ocean 0.45× too small, ~5 months apart. The land and ocean corrections are ONE fix.**

## 3. THE JOINT ARM — PRE-REGISTERED, RUN, AND CONFIRMED

Prereg `notes/prereg_2026-08-27j_joint_land_ocean_arm.md`, **committed `fa83faa` BEFORE
`calibration/diag_joint_land_ocean_refit.R` existed. No gate was moved.** Collect
`notes/collect_2026-08-27j_one_fix_confirmed_the_residual_is_still_land.md`, commit `7364f4c`.
All four arms converged (1 restart, last gain 0.0000). ~75 min.

**The design is a 2×2 and the statistic is parameter-BALANCED** — the reason for four arms:

    INTERACTION = JOINT − LAND_only − OCEAN_only + INCUMBENT,   npar 7−6−7+6 = 0

| arm | land | ent | vs INCUMBENT |
|---|---|---|---|
| LAND-only | GPP 0.352 | 0 | **−79.18** |
| OCEAN-only | PsnNet 0.5027 | 4.31 | **+11.93** (reproduces 27g: 4.16 / +11.62) |
| **JOINT** | 0.352 | **8.11** | **−2.26** (sum of singles **−67.25**) |

**⇒ INTERACTION +64.99 against a gate of +39.59 — 82 % of the land penalty recovered.**

**P0 PASS · P1 CONFIRMED · P2 PASS · P3 PASS · P4 FAIL · P5 FAIL · P6 PASS.**

- **P2:** `ent_seas_amp_SH` = **8.11 µmol/kg, inside the 5–30 physical band for the FIRST time**
  (27g landed 4.16, below it).
- **P3:** partition **1.93 → 1.390**, beating both singles (land 1.834, ocean 1.765). Best this arc
  has produced.
- **The ocean limb rotated 4.13 → 9.24 months** against an observed 8.52 — the quantity **27g's P3
  scored FAILED** on (3.35 → 3.45). ⚠ **This was NOT a 27j gate. Reported as measured, never quoted
  as a pass.**
- **LAND-only catches the cancellation in the act:** cutting land should make a compensating fit
  RAISE the ocean; instead `sst_seas_amp_SH` collapses to **0.176 (z −9.18)**, because the
  solubility limb at month 4.13 was ANTIPHASE to land at 10.11 and **subtracting**.

## 4. WHY P4 AND P5 FAILED — ONE REASON, SEEN TWICE

| at SPO | INCUMBENT | **JOINT** | OBSERVED |
|---|---|---|---|
| total | 1.138 @ 8.72 | **1.267 @ 8.68** | 1.168 |
| SH-local land | 1.315 @ 10.09 | **0.906 @ 10.08** | 0.683 |
| SH ocean | 0.253 @ 4.13 | **0.258 @ 9.24** | 0.522 @ 8.52 |
| δ¹³C-per-ppm | 1.940 | **1.390** | 1.000 |

At 9.24 the ocean limb is nearly IN PHASE with land at 10.08, so they now **ADD** where they
canceled — the assembly nature uses ([[seas_spo_two_wrong_pieces]]). But:

1. **SH-local land is still 0.906 = 1.33× the observed 0.683.** The GPP end was not far enough, so
   two in-phase parts overshoot → **P4, total 1.267 vs gate [1.114, 1.222]**.
2. **The wrong-phase solubility limb is still carried at `sst_seas_amp_SH` = 0.656** (37.6 % of
   observed, z −3.92), canceling the channel and holding the net ocean at 0.258 vs 0.522 →
   **P5, 0.495× vs a ≥0.75 gate**.

⚠ **`seas_T_amp_NH` lands at 31.41, prior z +3.50** — the largest positive flag in the slice, moving
the same way in EVERY arm (mode 23.46 → 29.9–33.3). Not caused by this experiment, not explained by
it, **not clean.** Do not quote the slice as tidy.

## 5. NON-OBVIOUS STATE — READ BEFORE TOUCHING ANYTHING

- **⚠ `R/likelihood.R:175`'s "66 % of `tau_ex`'s leverage came from the seasonal harmonics" IS NOW
  KNOWN TO BE HALF WRONG AND HAS NOT BEEN EDITED.** The measurement is in the 27h collect and
  CHANGELOG; `R/` was deliberately left untouched all day. **Editing that comment is a live, easy
  item and someone should do it deliberately rather than discover the discrepancy.**
- **⚠ `ccx_make_logpost()` still does not reproduce the canonical mode's stored `logpost`**:
  **−1547.9370 vs −1544.6148, offset −3.3223**, pre-existing, verified again four times today and
  identical every time. Matched comparisons are unaffected. **Never quote an absolute logpost from
  a live harness against the mode file.** [[ccx_mode_logpost_offset]]
- **⚠ SEVEN OF THE 21 CALIBRATED NAMES ARE LIKELIHOOD-SIDE AND ABSENT FROM
  `ccx_default_params()`** — `bomb_total`, `luc_scale`, `sigma_d14c`, `rep_dC`, `grad_off_co2`,
  `grad_off_d13c`. Read them off `pv` (the `ccx_unc_to_par()` list), never off `p`. `p$bomb_total`
  is NULL, `NULL/102` is `numeric(0)`, and `F$c14_bomb` silently becomes a zero-length column.
  **This cost a 12-minute run today.** All three new scripts carry the note.
- **⚠ `ccx_model_stats()` RETURNS A LIST OF COLUMNS, NOT A data.frame.** `nrow()` is NULL,
  `sprintf()` returns `character(0)`, `cat()` prints **nothing and raises no error** — a whole
  report block vanished silently. Use `length()` and gate it.
- **⚠ `ccx_total(y)` takes a STATE MATRIX, not the output series.** And an invariant annual mean was
  the wrong thing to assert anyway: a zero-mean flux CAN rectify through q10
  ([[seas_isotope_rectification]]). Gate the STRUCTURE (the driver factor integrates to 1.086e-16),
  MEASURE the rectification (level rows moved ≤ 0.06 across the whole grid).
- **⚠ AN UNDER-CONVERGED OPTIMUM AT A FIXED PARAMETER OVERSTATES THAT PARAMETER'S COST** — it
  manufactures the "unaffordable" verdict. 27h's first conditional run hit `maxit` at all three
  points and was **discarded**. The fix — continuation warm-start + BFGS polish + restart-until-
  still, with restart count and last gain PRINTED — is in all three new scripts. Never accept a
  silent `maxit`.
- **⚠ A GRID WHOSE SMALLEST STEP IS 8× THE BUDGET BEING ASKED ABOUT CANNOT ANSWER THE QUESTION.**
  27h's first grid went 1.00 → 1.26 in one 77-log-unit step, so every affordability rung resolved
  to "1.00×" and printed NA.
- **⚠ THE INVERSION'S "OBSERVED" LAND IS MODEL-SIGNATURE-DEPENDENT.** It inverts the observed
  harmonics through the model's own `s_L`/`s_O`, so it moves 0.683 → 0.676 with `tau_ex`. Small,
  but **do not quote it as purely observational.** Handoff 27h §4 quotes 0.665; the measured value
  at the mode is **0.683**.
- **NEVER EDIT A SCRIPT WHILE `Rscript` IS READING IT.** Every long job today ran from a frozen copy
  in `/tmp`, which is what made mid-run edits safe. Parse-check every touched file first.
  [[never_edit_a_running_script]]
- **`seas_npp_amp_SH` and `ent_seas_amp_SH` are BOTH outside `CCX_PARAM_TABLE`** and always will be
  while they stay out. Anything reading a mode gets the constant / 0 unless told otherwise.

## 6. ⇒ THE TWO DECISIONS OWED

### (i) A MODELING CHOICE — where next

- **(A) RE-DERIVE THE (shape, size) PAIR — my recommendation.** `CCX_SEAS_PHI_EFF['SH'] = −30` and
  `SEAS_NPP_AMP_SH` fitted TOGETHER against the observed SH productivity cycle, as `R/constants.R`
  says they must be ("the pair is a (shape, size) unit, not two independent numbers"). The residual
  is a land SIZE error of 1.33×, the size is half of a pair, and **the SH shape has never been
  re-fitted** — 75 won that contest in the NH, −30 was not tested the same way.
  [[ccx_phi_eff_amplitude]] already reports the latitudes right and the amplitude not.
- **(B) PIN `sst_seas_amp_SH`, or price it honestly.** It sits at 37.6 % of observed, z −3.92,
  canceling a channel that now works. [[orthogonality_bounds_efficiency]] — pin the lever when the
  conclusion needs it, and measure the exchange rate rather than arguing about it.
- **(C) 4b, the second SH ocean column.** Not ruled out, **no longer indicated**: the existing
  channel reached its physical band and the right phase. Revisit only if (A) and (B) leave a
  residual that is genuinely oceanic.

### (ii) NOT A MODELING CHOICE — is the model ENTITLED to the GPP end?

**`seas_npp_amp_SH` was FIXED, not fitted, in every arm.** A clean interaction shows the two
corrections COUPLE. **It does not show that 0.352 is the right value.** PsnNet and GPP disagree by
**1.4×** and the model currently uses one end **without saying why**. Adopting the other end because
it improves a fit is precisely the move this project's own conventions exist to stop.

**This one is Marcus's on the measurement's terms, and it should be settled BEFORE (A) is designed
around it** — because (A) re-derives that very constant, and it should be re-derived against the
observation, not against the fit.

## 7. STILL OPEN BEHIND THIS

- **`R/likelihood.R:1028/1091/1178` — `co2_NH` maps to MLO with a LEVEL offset and NO seasonal
  amplitude representation term.** Still unchecked, still cheap, NOAA's network measures it.
  ⚠ Direction matters: the NH hemispheric mean is LARGER than MLO, so correcting it makes the NH
  box bigger and the import WORSE. Worth doing to know, not as a fix.
- The δ¹³C Suess overshoot re-check; `gcb_land_sink` (−7.94, +2.31 σ, `LIK_LAND_SINK_INFLATE` 3.0);
  **`kz` railing** (6332 vs a bracket top of 6528 — and 4b would land on it); the pump's
  `alpha13_signed` (b) case; `alpha_as_*` hardcoded, uncited, temperature-independent under a
  seasonal SST cycle; the Hessian condition number; **the sampler — still the project's oldest open
  item, and there is STILL NO POSTERIOR.**

## 8. HOW TO RUN WHAT EXISTS

    Rscript calibration/diag_tau_ex_seasonal_power.R        # ~12 min
    Rscript calibration/diag_tau_ex_conditional_power.R     # ~35 min, needs the RDS above
    Rscript calibration/diag_seas_npp_sh_power.R            # ~50 min
    Rscript calibration/diag_joint_land_ocean_refit.R       # ~75 min, four arms
    CCX_PAR_RDS=<overrides.rds> Rscript calibration/diag_seas_signature_inversion.R

Outputs in `outputs/diagnostics/`: `tau_ex_seasonal_power.rds`, `tau_ex_conditional_power.rds`,
`seas_npp_sh_power.rds`, `joint_land_ocean_refit.rds` (all carry the full landed vectors).
Pin BLAS to one thread and check `uptime` before launching. [[eta_in_days_is_not_a_slow_run]]
