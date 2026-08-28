# Handoff — CarbonCycleEmulator, 2026-08-28: **THE MODE'S `h_ml` WAS DECODED WRONG FOR WEEKS, AND THE BOUND GUARDS A FREE LUNCH**
# Four arcs: the 27q 2×2, the four unmeasured gates, the `h_ml` band-decode defect, and the unbound profile.

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, trunk `main`, **clean at `54fe499`**.
**Nothing is running.** **Suite: 1164 pass / 0 fail** (1157 + 7 new). Eleven commits, `77c6651..54fe499`,
opening from `bb2623e` (the 27o handoff).

⚠ **THE SESSION CWD WAS `FaIRtoFrEDI/`, BUT ALL OF THIS WORK IS IN `CarbonCycleEmulator/`.** Keep
these notes here.

---

## 0. STATE IN TEN LINES

1. **27q ran the 2×2 with the ADMISSIBLE lever.** The coupling MECHANISM replicates in full, but
   the channel recovers **~43 %** of the land penalty against 27j's **~84 %**, so **P1 is FALSIFIED
   at both bracket ends.** §1
2. **Four DESIGN gates — 6, 8, 10, 11 — had NEVER been measured at any fitted vector**, including
   the seasonal-amplitude gate for the arc that has been live since 08-27f. Now measured. §2
3. **Gate 6's TARGET ROW IN DESIGN WAS WRONG** — not by rounding: the data is monotone where the
   transcription dipped. Corrected, with the old row and vintage recorded. §2
4. ⚠ **`ccx_unc_to_par(md$u_mode)` DECODES `h_ml` UNDER THE SHIPPED BAND AND GIVES 85.73 m WHERE THE
   REFIT FOUND 96.47 m** — 11.1 %, and the only affected parameter of 21. §3
5. **THAT IS THE STANDING −3.3223 OFFSET, EXACTLY.** Recorded-band decoding leaves **−1.5805**, which
   IS the bounded refit's narrowed-prior constant. `|residual − constant| = 0.0000`. **CLOSED.** §3
6. **10 drivers swept, every arc re-run, and NO VERDICT MOVED** — because the mixed layer sets the
   ocean's carbon CAPACITY while the SPO seasonal AMPLITUDE is driven by `sst_seas_amp_SH` and the
   entrainment channel. §4
7. ⚠ **IT RETRACTS MY OWN 08-27 CLAIM** that the softest posterior direction is non-differentiable.
   The Hessian's `h_ml` row is CLEAN; the refit's guards were right. §3
8. **THE UNBOUND PROFILE: 08-16g's "argmax 32 m, pull 236" DOES NOT REPRODUCE.** With the uptake set
   free the argmax is **75 m**, the pull beyond the cliff is **0.09**, and 32 m is **4.57 WORSE**. §5
9. **THE CLIFF *IS* THE THREE SKIPPED ROWS, TO 0.3 %** (−7.275 vs −7.300). ⇒ the bound is
   load-bearing, but **it bears a FREE LUNCH, not physics.** §5
10. **Marcus leans OPTION 5 (σ-inflation)** and asked for the profile first. The profile supports the
    lean — ⚠ **but at the measured 21 % residual, inflation reduces the pull 80 %, NOT to zero.** §6

---

## 1. 27q — THE 2×2 WITH THE ADMISSIBLE LEVER

Prereg `36e4051` BEFORE the driver; `calibration/diag_admissible_2x2_land_ocean.R`;
collect `notes/collect_2026-08-27q_...md`. Six arms (LAND and JOINT at BOTH the prior centre 5.0502
and bracket HI 7.1012, because which end to pin is a methodological choice and measuring is cheaper
than picking). Both interactions parameter-balanced, 5−4−6+5 = 0.

**P1 ✗✗ · P2 ✓✓ P3 ✓✓ P6 ✓✓ P7 ✓✓ P8 ✓✓ · P4 ✗✗ P5 ✗✗** (post-sweep numbers)

- **Interactions +34.47 (mid) / +70.89 (hi)** against gates 40.21 / 81.07 — **82 %/84 % of gate**.
  **Recovered fraction 42.9 % / 43.7 %** across a 2× range of land cost, vs 27j's **83.6 %**.
  ⇒ **the channel supplies a fixed FRACTION of the vacancy, not a fixed amount.**
- **NOT a null.** `ent` sits at **4.31 BELOW the 5–30 band** in OCEAN_only and moves **INSIDE**
  (5.97, 7.16) the moment the land is pinned — **27j's suppression/release claim, replicated with
  the admissible lever.** Limb rotates 4.17 → 9.47 mo. `sst_seas_amp_SH` recovers 0.153 → 0.488.
  **P8: JOINT SH-land is IDENTICAL to LAND-only ⇒ the refit does NOT undo the land fix**, so the
  shortfall is a real residual cost, not 27n's buy-back mode.
- **WHY IT FAILS IS GEOMETRY.** The limbs were **5.9 mo apart and SUBTRACTING**; rotating the ocean
  is correct physics but removes that cancellation and exposes land **1.26×** obs against ocean
  **0.53×**, which now ADD — total **1.382** vs obs 1.168.
- ⚠ **My predictions were 2 of 4.** The P4 miss is the one to remember: I argued the two errors would
  oppose, **treating two limbs as SCALARS when they are VECTORS**, with the phase columns in front
  of me. **Check the angle before predicting a sum.**

⇒ **The defect is now an AMPLITUDE PAIR (land 1.26×, ocean 0.53×) that can no longer hide inside a
cancellation. 4b — the SH ocean AMPLITUDE as distinct from the phase channel — is the indicated
next target; P5 has now failed three times (27g, 27j, 27q) for the same reason.**

## 2. THE FOUR UNMEASURED GATES

`calibration/diag_design_gates_unscored.R` (new). `diag_design_gates_at_mode.R` covers 4/5/7/9,
`diag_joos_irf.R` covers 12, gates 1–3 are the suite — **6, 8, 10 and 11 had nothing.**

| gate | verdict at `from90` |
|---|---|
| **6** MLO seasonal growth | **PASS** +21.0 % vs observed +14.8 %; **defaults are 3× too small** (1.97 vs 5.95 ppm) |
| **8** δ¹³C Suess decline | **FAIL** — over-declines +0.214 ‰ (MLO) / +0.143 ‰ (SPO). Spinup targets ARE met, so not a spinup problem; the overshoot is LARGER in the NH |
| **10** deep natural Δ¹⁴C | **FAIL** — calibration **CROSSED** the target: defaults z −1.46, fitted z **+1.71** |
| **11** uniformity screen | 4/4 flag ALL-SAME-SIGN, all R² ≤ 0.14 ⇒ pure LEVEL bias, the expected already-diagnosed result |

⚠ **GATE 6'S TARGET WAS WRONG IN DESIGN.** The transcribed
`5.95/6.17/6.40/6.42/6.38/6.86/6.66` is not what `build_calibration_data.R:583-588` produces on
`data/obs_co2_monthly.rds`; verbatim it gives `5.95/6.13/6.30/6.47/6.65/6.83/6.97`, and
`ccx_prepare_obs()` reproduces that exactly — **the data path was never at fault.** The two disagree
QUALITATIVELY: the data is **monotone increasing** where the old row **dipped** at the 2000s and
2020s. Largest error 0.27 ppm against a 0.88 ppm growth signal = **~30 % of what the gate tests.**
Corrected in DESIGN §6 with the old row and the data vintage recorded.

⚠ **Gate 6 must be read on GROWTH, not levels.** Scripps' `co2_deseas` and a 12-month MA on the SAME
observed record differ by up to **0.449 ppm** (~7 % of the amplitude) while their growth ratios
differ by **0.0065**. Only the MA has a model counterpart, so the model is compared on it.

## 3. THE `h_ml` BAND-DECODE DEFECT — AND WHAT IT RETRACTS

`calibration/diag_hml_mode_decode.R`; fix + guard in `R/paths.R`; `tests/testthat/test-mode-decode.R`.

`h_ml` is logit-transformed onto `[lo, hi]` and the pump refits **override that band IN PROCESS**
(`run_modefind_pump_arms.R`, `recompute_hessian.R:112-113`) because the band is a property of the
REFIT. `ccx_unc_to_par()` is a pure function of the SHIPPED table and cannot know:

    ccx_unc_to_par(md$u_mode)$h_ml   85.7292 m     <- what every diagnostic used
    md$par_mode[["h_ml"]]            96.4737 m     <- what the refit FOUND

**11.14 %, and `h_ml` is the ONLY one of 21 that moves.** Recorded-band decoding takes the standing
offset **−3.3223 → −1.5805**, and −1.5805 **is** the narrowed-prior constant: `|residual − constant|
= 0.0000`. **`ccx_mode_logpost_offset` is CLOSED**; its own note listed "the h_ml refit bound" among
things RULED OUT, and that ruling-out was wrong.

⚠ **THIS RETRACTS MY 08-27 CLAIM** that the softest posterior direction is non-differentiable. At the
true 96.47 m the nearest pump kink is **1.94 m** away against a Hessian reach of **0.366 m**, so
`hml_kink_hit = FALSE` was CORRECT and **the Hessian row is clean**. `h_ml` is soft (1σ ≈ **11.00 m**)
but not kinked where it is measured. **The refit's own guards were right; my decoding was not.**
What SURVIVES: condition number **1.11e6**, softest/stiffest **1055×**, `h_ml` and `kz` as the two
softest directions, `kz` railing.

⚠ **The defect was ALREADY DOCUMENTED, in one file** — `diag_landed_gap_streams.R:36-37` — and never
propagated. **A trap documented once is not thereby fixed everywhere.**

**THE GUARD:** `ccx_mode_params()` (use instead of `ccx_unc_to_par(md$u_mode)`),
`ccx_adopt_mode_band()` (repairs ALL decodes in a driver including inside `ccx_make_logpost()`), and
`ccx_check_mode_decode()`, which **ERRORS**; the test asserts the affected set is **exactly `h_ml`**.

## 4. THE SWEEP — AND WHY NOTHING MOVED

**10 patched** (8 via `ccx_adopt_mode_band()`; `design_gates_unscored` via `ccx_mode_params()`
because it runs several mode files with possibly different bands; `phi_eff_profile` inside its
generated worker). **4 already applied the band by hand**; **7 already used `md$par_mode`** —
including **`app/global.R`, so the shipped app was NEVER affected**. **2 dead** (`profile_*` read a
`mode_fit.rds` that does not exist). Pre-fix outputs: `outputs/quarantine/20260828_hml_band_decode/`
with a README.

    27g z -3.43 -> -3.45 | 27h identical | 27i -79.01 -> -80.27
    27j INTERACTION +64.99 -> +67.28  CONFIRMED (82.1 -> 83.6 %)
    27n P8 1.79x -> 1.78x | 27p 71.8 -> 71.9 % closed, S0-S5 PASS
    27q +32.81/+67.76 -> +34.47/+70.89  FALSIFIED (42.9/43.7 %)
    gates 6/8/10/11 identical verdicts

**27j's four P0 controls moved by ≤0.001 across an 11 % change in `h_ml`.** ⚠ **ONE THING CHANGED IN
KIND:** 27q's P0 reproduced 27j's controls *because both sessions shared the defect*; both are now at
96.47 m and still agree, so **the cross-session claim is finally EARNED.**

**Two more bugs the sweep flushed out:** `diag_seas_T_amp_sh_power.R`'s `sprintf(" %>10s")` — an
invalid format that ABORTS, never executed because the original run took the try-error branch (the
streams bug 27o §7 records). And my own 27p driver printed a **hardcoded** `QP_S1_FREE = 1.2256`
beside a figure that WAS read from the rds, so re-running 27n moved one and not the other.

## 5. THE UNBOUND PROFILE — THE 236 DOES NOT EXIST

Prereg `805e8c4` BEFORE the driver; `calibration/diag_hml_unbound_profile.R`; 26 points, all
converged. `h_ml` fixed over the **SHIPPED** [30, 200], `beta_max`/`fert_k`/`k_w`/`kz`/`pump_grad`
re-optimised at each point — the configuration never previously run. **H1 ✓ H2 ✗ H3 ✗ H4 ✗.**

    198 off +3.19 | 160 off +6.02 | 120.01 off +7.03 || 119.99 LIVE -1.40
    96.47 LIVE +0.00 (mode) | 85.01 LIVE +0.35 || 84.99 off +7.65
    75 off +7.74 ARGMAX | 55 off +7.34 | 38 off +5.35 | 32 off +3.17

1. **In-band the objective is FLAT** — +0.00 → +0.35 over 11.5 m, optimum at the SHALLOW end.
2. **Cliff −7.300 at 85, +8.426 at 120.**
3. **Beyond the cliff there is +0.09 of pull**, then it DECLINES. **32 m is 4.57 WORSE than 75 m.**

**08-16g's "argmax 32 m, pull 236 vs a 10.0 cliff, 24×" was measured with 19 params FROZEN and DOES
NOT REPRODUCE.** 5 free is CONSERVATIVE and ONE-WAY, so this **generalises to 20**.

**THE CLIFF *IS* THE THREE ROWS, TO 0.3 %:** just inside the edge they sum **−7.275** against a
**−7.300** cliff; outside they are **ABSENT from `ccx_loglik`'s output, not zero.** ⇒ **the bound is
load-bearing, but 7.30 of the 7.39 advantage at the argmax is three skipped Gaussians. The objective
does not prefer a shallower mixed layer — it prefers BEING SCORED ON LESS DATA.** At the upper edge
~1.0 is re-optimisation freedom on top (`pump_grad` 273.4 → 324.0).

**H3 ✗ and it INVERTS:** `kz` is pushed **HARDER** onto its rail as `h_ml` falls (92.4 → **98.2 %**),
releasing only going DEEPER (**57.7 %** at 198 m). **My hypothesis had the sign backwards.**
**H4 ✗:** `pump_grad` stays **226–446**, never near 963.6/1431.0 — ⚠ not a refutation (those came
from truncated arms with far more freedom).

## 6. ⇒ THE NEXT ARM (NOT RUN, NOT PRE-REGISTERED) — AND MARCUS'S STANDING CALL

**Marcus 2026-08-28: "I would profile h_ml, but lean towards option 5 as being more scientifically
appropriate."** The profile supports that lean and names exactly what inflation must charge for.

⚠ **BUT THE ARITHMETIC DOES NOT FULLY CLOSE.** At 08-16g's measured **21 % residual**, inflation
applied to this 7.30 cliff leaves ≈**1.53**, so the out-of-band argmax falls +7.74 → **≈+2.0**
against an in-band +0.35: **the pull drops 7.39 → ~1.6, an 80 % REDUCTION, NOT ELIMINATION**, and
the argmax would still sit just outside the band. ~1.6 is comparable to the refit's own ~0.7 restart
noise floor, but it is not zero and it is directional.

⚠ **AND THAT 21 % IS OBSERVATION-SIDE ONLY** — it has never been measured with the model's own
gradient. **PROPOSED: re-run the out-of-band points of §5 with σ-inflation ON and read the argmax
directly**, instead of scaling a number from another configuration. That is cheap (the points are
83–241 s each), well-posed, and it is what would let option 5 be adopted on a MEASUREMENT rather
than an inference. **Marcus's call; nothing here preempts it.**

## 7. NON-OBVIOUS STATE — READ BEFORE TOUCHING ANYTHING

- ⚠ **USE `ccx_mode_params()`, NEVER `ccx_unc_to_par(md$u_mode)`**, whenever the parameters are meant
  to BE the mode. In a driver that also perturbs `u`, call **`ccx_adopt_mode_band(md)` once** after
  reading the mode — it repairs the decodes inside `ccx_make_logpost()` too.
- ⚠ **THE HARNESS OFFSET IS NOW −1.5805, NOT −3.3223.** Eight drivers were updated. A driver still
  gating on −3.3223 has not been swept.
- ⚠ **`ccx_loglik(by_stream = TRUE)` RETURNS A NAMED NUMERIC VECTOR**, so `s[["absent_name"]]`
  **ERRORS** rather than returning NULL. **Test membership, never nullity.** This is documented in
  memory `ccx_hml_band_discont` and I still walked into it.
- ⚠ **WRITE THE ARTIFACT BEFORE THE PRETTY-PRINTING.** A reporting bug destroyed 45 minutes of fits
  because `saveRDS` came after it.
- ⚠ **Long background runs were being REAPED.** Several 40-minute jobs died with the column header
  written and no rows — R's buffered stdout went with them. `flush.console()` after every row, and
  hold the process with a foreground poll rather than trusting `nohup … &` to survive.
- ⚠ **`SEAS_NPP_AMP_SH`'s stated sd of 0.087 STILL BADLY UNDERSTATES its uncertainty** (5 MOD17 years
  against a 1.9× product disagreement and a 5.3× ridge). Still `status = "data"`. **Provenance edit,
  Marcus's.**
- **The basis decision (27o §8) is STILL OPEN** — the measuring is done; the SH insolation fit has no
  interior optimum and a ~12 % floor.
- `md$u_mode` — **spell it out**; R's `$` partial-matches `md$u`.
- **Seven of the 21 calibrated names are likelihood-side** and absent from `ccx_default_params()` —
  read them off `pv`, never `p`.
- ⚠ **`MEMORY.md` root is ~16.7 KB against a 12 KB soft target.** Not restructured — flagged only.

## 8. STILL OPEN BEHIND THIS

- **The controlled lever contrast** (27q §4): 27j's `seas_npp_amp_SH` on the PINNED slice, changing
  only the land knob. The 83.6 %/43 % gap is across DIFFERENT slices and is **not controlled**.
- **4b — the SH ocean AMPLITUDE**, which P5 has failed three times for the same reason.
- **`kz` RAILING** (6332 vs 6528, 92.4 %), now known to be pushed harder by a shallower `h_ml`.
- **THERE IS STILL NO POSTERIOR** — the project's oldest open item. `posterior_draws.rds` does not
  exist, so the app's flagship IRF ships as a point estimate with no band.
- Gate 8's Suess overshoot; gate 10's crossed target; the δ¹³C `alpha_as_*` provisional constants
  (`model.R:1701-1702`) and `co2_NH`'s missing seasonal representation term — all **objective
  changes**, none of them an easy fix.

## 9. HOW TO RUN WHAT EXISTS

    Rscript calibration/diag_hml_mode_decode.R           # seconds, the decode defect + offset
    Rscript calibration/diag_design_gates_unscored.R     # ~2 min, gates 6/8/10/11
    Rscript calibration/diag_design_gates_at_mode.R      # ~1 min, gates 4/5/7/9
    Rscript calibration/diag_hml_unbound_profile.R       # ~45 min, 26 points -- HOLD THE PROCESS
    Rscript calibration/diag_seas_slice_q10_pin.R        # ~5 min, needs 27n's rds first
    Rscript calibration/diag_seas_T_amp_sh_power.R       # ~1 h, the q10 ridge section is the slow one
    Rscript calibration/diag_admissible_2x2_land_ocean.R # ~15 min, six arms
    Rscript tests/run_tests.R                            # ~4 min, 1164/0

Outputs in `outputs/diagnostics/` (11 files, all band-corrected); pre-fix set in
`outputs/quarantine/20260828_hml_band_decode/`. **Run long jobs from a FROZEN COPY, pin BLAS to one
thread, check `uptime` first, and hold the process.**
