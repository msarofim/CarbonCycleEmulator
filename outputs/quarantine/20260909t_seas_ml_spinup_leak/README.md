# QUARANTINE — outputs produced while `seas_ml` LEAKED INTO THE ASEASONAL SPINUP

**Created 2026-09-09t** by the whole-model code review. **⛔ CORRECTED 2026-09-09v after the
re-runs: FOUR OF THE FIVE FILES HERE WERE NEVER CONTAMINATED.** The original attribution below
(§1) is right about the bug and wrong about its blast radius. Read §2a before citing anything here.

---

## 1. Which bug applies (UNCHANGED — the bug is real and was measured)
One mechanism gated on **two different objects**:

- **R** gated on `ccx_seas_ml_on(p)` (`R/model.R:853`), which requires `p$seas_drivers > 0`.
- **C++** gated on `A.seas_ml`, and that flag was `as.integer(!is.null(aux$mld_coef))`
  (`R/cpp.R:50`) — **a function of `aux` ALONE**.

`ccx_spinup()` builds `aux <- ccx_prepare(p)` from the **un-zeroed** `p` (`R/spinup.R:151`) and only
**then** sets `p0$seas_drivers <- 0` (`:227`) — and every equilibrium solve runs through the C++
path. So the zeroing was honoured by R and **ignored by C++**.

**RE-MEASURED 2026-09-09v** at `hilda31`, by running one probe in two frozen trees differing only
by the documented one-line mutation (`calibration/diag_seas_ml_spinup_leak_probe.R`):

| | `seas_ml = 0` | `seas_ml = 1` | Δ |
|---|---|---|---|
| pre-fix ocean C | 37 894.163 GtC | 35 953.939 GtC | **−1 940.224** |
| post-fix ocean C | 37 894.163 GtC | **37 894.163 GtC** | **0.000** |

Post-fix `max|dy|` over all 36×3 state is **exactly 0** on every arm. ✅ The fix works, and the
review's −1940.224 is reproduced to the digit.

---

## 2a. ⛔ WHICH FILES WERE ACTUALLY AFFECTED — the 09-09t list was too wide

**The C++ core could not carry the seasonal mixed layer until commit `4189ff9`, 2026-09-09 16:33.**
Three independent lines establish it, and the third is a direct measurement:

1. `git show 62966de:src/ccx_core.cpp | grep -c seas_ml` → **0**. No `seas_ml`, no `mld_*`.
2. At that commit `ccx_cpp_par()` carried `if (ccx_seas_ml_on(p)) stop("the C++ core has no
   seasonal mixed layer yet …")`. `ccx_spinup()`'s zeroing meant the equilibrium solve never
   tripped it — and was therefore **correctly aseasonal**. The R gate was the ONLY gate, and it
   was right.
3. **The re-runs.** Every file below was re-run post-fix to its canonical path and diffed.

| file | ran at | vs 16:33 | re-run diff |
|---|---|---|---|
| `seas_ml_convergence_20260909.{rds,log}` (P9, P10) | 13:01 | **before** | ✅ **BIT-IDENTICAL** |
| `seas_ml_probe_20260909.{rds,log}` (P1, P1a, P1b) | 14:34 | **before** | ✅ **BIT-IDENTICAL** |
| `p12_compensator_20260909.{rds,log}` (P12) | 15:18 | **before** | ✅ **BIT-IDENTICAL** |
| `p12_streams_20260909.log` (derived from P12) | 15:20 | **before** | ✅ **BIT-IDENTICAL** |
| `p1c_dpco2_20260909.{rds,log}` (P1c) | 16:43 | **after** | ⛔ **DIFFERS — the only real one** |

⇒ **Only `p1c_dpco2` is a quarantined output.** The other four are kept here as provenance of the
over-collection, and are byte-identical to the live copies in `outputs/diagnostics/`.

⚠ Over-collecting was the SAFE error and the re-run was owed either way. Recorded because the
*reasoning* that produced it is the interesting part — see §2b.

## 2b. ⛔⛔ THE READING THAT WAS WRONG, AND WHAT THE NUMBER ACTUALLY IS

The 09-09t version of this file said P12's *"pays −514 on the two CO₂ LEVEL rows"* and P10's *"the
mechanism CHANGES ANTHROPOGENIC UPTAKE"* were **"the exact signature of a ~1 940 GtC ocean-carbon
deficit at t₀"**. **Both are false.** Both diagnostics ran on code where the deficit was
unreachable, and both reproduce bit-identically after the fix.

⭐ **That inference is [[explained_away_test]] run backwards**: a real result was explained away by
a bug that had not yet been written. Two diagnostics agreeing was read as a shared *bug*, exactly as
09-09t warned against reading it as shared *corroboration*.

**What −514 actually is, measured 09-09v** (`outputs/diagnostics/f2_periodic_spinup_20260909.log`):
a quiet run (zero fossil, zero LUC flux and stock, held climate, zero AOD) started from the
aseasonal spinup shows the mechanism imposing **+19.94 ppm at 1750, decaying to +2.51 ppm by 1770
and then FLAT within 0.07 ppm (2.37-2.49) for the next 480 years** (`seas_ml = 0` noise floor: 0.021 ppm; ratio 855×).

- The **transient** cannot cause the level-row penalty: `co2_level_MLO`/`SPO` score **1959–2025 /
  1962–2023**, ~190 yr after it is gone. It lands on `co2_icecore` (1703–1996), which P12 measured
  at only **−2.84** — consistent with that stream's wide σ.
- The **flat +2.45 ppm rectified offset** is the right epoch and the right size. At the shipped
  `LIK_CO2_REP_ERR = 1.0` ppm over n = 126 annual points, the measured **−514.38** corresponds to a
  uniform offset of **+2.857 ppm**. F2's preindustrial residual is **+2.45**; the remainder is
  P10's industrial-era uptake change. ⇒ **P10 and P12 are one finding, and it is physics.**

---

## 3. Canonical post-fix replacements
All five basenames are now regenerated in `outputs/diagnostics/` (2026-09-09v). Cite those.
**P1c is the only one whose numbers moved:**

| | pre-fix | post-fix |
|---|---|---|
| SH ΔpCO₂ amplitude, `seas_ml = 1` | 40.76 µatm | **54.04 µatm** |
| ratio vs A1 (0–90 S, the ruling) | 9.11 | **12.09** |
| ratio vs A2 (40–90 S, reference) | 2.64 | **3.50** |
| peak month | 6.83 | 6.79 (phase barely moves) |

⛔ **The leak was SUPPRESSING the over-swing.** The refit's amplitude-cut task is **harder** than
09-09s thought: 3.50× against the A2 band, not 2.64×.

## 4. What is NOT quarantined, and must not be
- `seasonal_ml_geometry_20260909.{rds,log}` — pure geometry, no `ccx_spinup`/`ccx_run` call.
- `so_pco2_amplitude_20260909.{rds,log}` — **ran at 16:36, INSIDE the contaminated window**, and
  checked 09-09v: it is observation-only (no model call), so it is correctly excluded. Its
  19.45-vs-16.26 estimator finding stands and is load-bearing for `ent_seas_amp_SH`'s prior centre.

## 5. Why kept rather than deleted
They are the regression test for the fix and the only measure of the bug's size. The pre-fix
behaviour is reachable in one line — drop the `seas_drivers` conjunct in `ccx_cpp_par()`:
`p$seas_ml_on <- as.integer(!is.null(p$seas_ml) && p$seas_ml > 0)` — which is the mutation used both
to confirm `tests/testthat/test-parity.R`'s new tests and to produce §1's pre-fix column.
