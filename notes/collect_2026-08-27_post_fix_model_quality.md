# Collect — 2026-08-27: whole-model quality re-established post-fix (7a, 7b, 7c items 1–2)

Executes §7 of `handoff_2026-08-27_post_fix_model_quality.md`. Commits `aa1c5e1`, `2779463`.
Everything below is measured at the canonical mode `from90`
(`calibration/output/refit_20260825f_from90/mode_fit_pumpN.rds`, logpost −1544.61,
`fert_k` 154.85), post the 2026-08-25f seasonal-NEP isotope fix `6bda464`.

---

## 1. §7a — mode resolution repointed, and the literal is now LINTED OUT

`ccx_mode_file()` in `R/paths.R` is the ONE place the canonical mode is named.
`CCX_MODE_CANONICAL` = `"from90"`; `CCX_MODE_FILES` names the two post-fix arms;
`CCX_MODE_RETIRED` makes `N`/`D`/`ref` **error with the reason** (quarantine directory +
the fix commit) rather than file-not-found. **`ref` is refused deliberately** — its
`mode_fit_pumpN.rds` is the pre-fix SEED, not a result.

**38 sites converted**, plus `app/global.R` and `app/DEPLOY.md`.
`tests/testthat/test-mode-file.R` lints the literal out of `R/`, `calibration/`, `app/`
with five declared exemptions (paths.R, the three files that WRITE arm files, and the
deliberate pre-vs-post comparison). Same construction as `test-luc-scale.R`'s lint.

**`CCX_MODE_PINNED` records which arms are FREE, and it exists because the stored
logposts are a trap.** `pin90` stores **−1544.50**, HIGHER than the canonical mode's
−1544.615. Its objective carries a near-delta prior on `fert_k` worth **+11.6698**, so on
the free scale it is **−1556.17 — 11.56 BELOW**. The test asserts the canonical mode is
FREE, *and* asserts the trap is still live, so the comment cannot go stale silently.

Two live-path defects fell out of the conversion, both invisible before it:
- `diag_design_gates_at_mode.R`'s τ_ex profile read `V$N`, which no longer exists → the
  script **crashed** at that section. Now `V[[DG_SHIPPED]]`.
- `ccx_path()` was wrapped around ten paths that `ccx_mode_file()` returns ABSOLUTE,
  which would have double-rooted them.

---

## 2. §7b — DESIGN §6 re-measured. THREE OF FOUR GATES MOVED.

Measured at `from90`, `pin90` and `defaults`. Every §6 status block was rewritten; the
pre-fix blocks are kept in `<details>` marked not-comparable rather than deleted.

| gate | pre-fix mode | **`from90`** | `pin90` | verdict |
|---|---|---|---|---|
| 4 AF level | 0.434 | **0.413** | 0.391 | GCB 0.431 — **worse** |
| 4 decadal sd | 0.019 | **0.026** | 0.036 | obs 0.051 — still ~2× smooth |
| **4 AF trend/dec** | **−0.0007** | **+0.0080** | +0.0137 | obs +0.0148 — **SIGN FIXED** |
| 5 NH→SH bomb lag | 0.92 | **0.97** | 0.97 | obs 1.34 — **FAILS** |
| 5 NH peak ‰ | 888.5 (+33) | **873.1 (+18)** | 875.4 | obs 855.3 — halved |
| 7 land σ | +2.12 | **+2.46** | +3.03 | **FAILS, further out** |
| 7 ocean σ | −0.64 | **−0.67** | −0.55 | **PASSES** |
| 12 TH 20/50/100 | ✗✗✗ | **✗✓✓** | ✓✓✓ | **first pass at any fitted mode** |
| 12b tail ratio | 0.707 | **0.709** | 0.716 | Joos 0.787 |

**Gate 12 went from failing all three horizons to passing two** — 12.14 (−0.48 %) /
24.98 (+4.08 %) / 41.11 (+4.07 %). TH 20 is the narrow remaining miss. The instruction to
quote TH 50/100 as "at the floor" is withdrawn a second time: they are inside with 4 %.

**Gate 12b moved 0.707 → 0.709 while 12a moved from 0-of-3 to 2-of-3.** That is 12b doing
its job: 12a is sensitive to the calibration, 12b tests STRUCTURE, which the fix did not
touch.

**Also withdrawn:** `diag_joos_irf.R`'s header claim that the model is "INSIDE BOTH" of
Joos §4.4.1's PI/PD ranges is **false at every vector on disk** — PI 27.4 against 34–47,
PD 43.8 against 45–62. The ORDERING (PI < PD) passes; the LEVELS do not.

---

## 3. §7c.1 — `diag_fit_at_mode.R`: THE RANK-ONE FINDING TIGHTENED 150×, AND THE
## COMMON-MODE d¹³C BIAS IS GONE

All 14 reconstructed streams reproduce their stored logL (gate OK on every row).

**[[ccx_fit_at_mode]]'s rank-one result is not merely intact — it is now an identity to
the fifth decimal:**

```
d13c level bias MLO   +0.04215 permil
d13c level bias SPO   -0.04299 permil
MLO - SPO             +0.08514 permil
fitted grad_off_d13c  +0.08512 permil        <- DIFFERENCE 0.00002 permil
```

Pre-fix this agreed to 0.003 ‰; it now agrees to **0.00002 ‰**. `grad_off_d13c` does
exactly one job — absorbing the MLO−SPO level-bias difference — and does it exactly.

**AND THE COMMON MODE HAS COLLAPSED.** The two station biases are now
**+0.84 z / −0.86 z**: equal and opposite to 0.02 z, mean **−0.00042 ‰**. Pre-fix
(08-22 correction) they were +1.12 / −0.77, mean +0.175 z. **The residual d¹³C level
misfit is now PURELY ANTISYMMETRIC — a gradient error, not a level error.**

⇒ **[[ccx_fit_at_mode]]'s design recommendation is now unmotivated.** It argued for "ONE
shared representation parameter generating BOTH species' level offsets by mass balance,
priored at 1.0 ppm". That parameter existed to absorb a common-mode d¹³C bias. There is
no longer a common-mode d¹³C bias to absorb. **Do not build it.**

RMS-z ranking (worst first): `d13c_level_SPO` 1.22, `d13c_level_MLO` 1.20,
`co2_seasonal_MLO` 1.14, `co2_seasonal_SPO` 1.09, `d14c_SH` 1.02, `d14c_NH` 0.98,
`co2_icecore` 0.78, `d13c_gradient` 0.78, `gcb_land_sink` 0.72 … `d14c_intcal` 0.38.
**Nothing is grossly misfit.** The two d¹³C level rows lead the ranking, but as the
antisymmetric pair above, not as a shared offset.

`d14c_SH`'s de-biased scatter (10.73 ‰) is **BELOW** its fixed representation floor
(10.96 ‰) — the fitted `sigma_d14c` = 6.11 explains nothing there. `d14c_NH` has real
scatter above floor. Unchanged in kind from pre-fix; re-recorded.

---

## 4. §7c.2 — `rep_dC` IS NO LONGER THE MODEL'S LARGEST PRIOR FLAG. THREE SEASONAL
## AMPLITUDES ARE.

`rep_dC` fell 5.566 → **3.378** prior sd. Smaller, still flagged, **and now only the
FOURTH-largest**. Ranked `|prior_z|` at `from90`, with the pre-fix arm-N value alongside
(the priors did not change; the OBJECTIVE did, so read this as where each mode SITS):

| param | pre-fix | **`from90`** | Δ |
|---|---|---|---|
| **`sst_seas_amp_SH`** | −4.25 | **−6.32** | **−2.07 (WORSE)** |
| `seas_T_amp_SH` | −3.95 | **−4.64** | −0.69 |
| `sst_seas_amp_NH` | **−6.22** | **−3.48** | **+2.74 (RELIEVED)** |
| `rep_dC` | +5.57 | **+3.38** | −2.19 |
| `npp_frac_NH` | −0.97 | +1.25 | +2.21 (crossed zero) |
| `q10` | −2.42 | −2.26 | +0.16 |

**THE FIX TRADED THE NH OCEAN-SEASONAL FLAG FOR THE SH ONE. The hemispheric asymmetry
INVERTED.**

**Priced on the RATIO, which does not depend on a prior width:**

| param | fitted | observed | ratio | note on the z |
|---|---|---|---|---|
| `sst_seas_amp_SH` | **0.360** | 1.746 | **0.21 — 4.9× too small** | width `SST_SEAS_LOGSD` = 0.25 is a **stated JUDGMENT** (DESIGN 5.2: "no bracket for it exists"), so −6.32 is partly a statement about that width |
| `sst_seas_amp_NH` | 0.937 | 2.237 | 0.42 — 2.4× too small | same caveat |
| `seas_T_amp_SH` | **1.039** | bracket **3.59–7.10** | **29 % of the LOW end** | bracket width = the weighting ambiguity, not a judgment |
| `seas_T_amp_NH` | 23.46 | bracket 11.45–17.92 | **131 % of the HIGH end** | " |

**The fit buys its seasonal cycle by cranking NH LAND far above any observed amplitude
while pushing SH land and BOTH oceans far below.** That is the partition finding
([[ccx_seas_partition]], "too photosynthetic") stated in the drivers rather than in the
δ¹³C-per-ppm observable — and it now has a clean hemispheric direction.

⇒ **This independently corroborates handoff §7c item 3's untested suspicion that the SH
residual is the larger and a single SH land box at an effective latitude is the suspect.**
Two of the three worst-flagged parameters in the entire fit are the SH seasonal
amplitudes. It also puts a live flag on §7d's `alpha_as_up`/`alpha_as_down` item: the
ocean seasonal limb is where two of the four amplitude flags sit.

---

## 5. A SMALL DEFECT FOUND, NOT PATCHED — gate 7's two reconstructions disagree, and
## the whole disagreement is the RUN'S LAST YEAR

DESIGN §6 gate 7 claimed the two independently written reconstructions "agree to the
reported precision". They do not: land 2015–2024 reads **3.590** (`diag_design_gates_at_mode.R`,
+2.46σ) against **3.525** (`diag_fit_at_mode.R`, +2.33σ). Isolated per year:

```
2015..2023   identical to 1e-4 in every year
2024         3.8793 (A)  vs  3.2268 (B)   +0.6525
```

**Both are wrong for 2024, differently.** The run ends at 2024, so neither file has a 2025
state to difference the land stock against; A extrapolates FLAT (`approx(rule = 2)`),
B extrapolates LINEARLY. Dropping 2024 gives 3.514 / **+2.31σ**.

**The verdict does not change** (FAIL land at +2.3 to +2.5σ), so this is not
result-changing. **The fix is a methodological choice and is Marcus's:** drop the
truncated final year from the gate-7 window, or extend the run to 2025 so the last
increment is real. Flagged, not silently resolved.

---

## What this does NOT cover (handoff §7c items 3–6, §7d)

Untouched: the seasonal partition test itself at ~1.5× (item 3, though §4 above hands it a
direction), the d¹³C Suess overshoot re-check (item 4), whether `gcb_land_sink` SHOULD be
decisive (item 5), `kz` railing (item 6, unchanged at 6332 against a bracket top of 6528),
the pump's `alpha13_signed` (b) case, `alpha_as_*`, the Hessian condition number, and the
sampler.
