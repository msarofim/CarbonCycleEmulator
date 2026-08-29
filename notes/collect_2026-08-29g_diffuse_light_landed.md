# COLLECT 2026-08-29g — **VOLCANIC DIFFUSE-LIGHT FERTILISATION IS IN, AND IT IS THE FIRST
# CHANGE THAT MAKES THE MODEL *MORE RIGHT* RATHER THAN LOUDER**
# r **0.571 → 0.625**. But the FROZEN likelihood cost is steep and must be priced CONDITIONALLY.

Implements plan item ① (`notes/plan_2026-08-29_implementation_order.md`), on Marcus's instruction
2026-08-29: *"go ahead with volcanic diffuse-light."*

---

## 1. WHAT WAS BUILT

**Mechanism.** Stratospheric aerosol scatters sunlight, raising the DIFFUSE fraction; a canopy uses
diffuse light more efficiently because shaded leaves receive more of it, so NPP rises after a large
eruption (Gu et al. 2003 *Science* 299:2035; Mercado et al. 2009 *Nature* 458:1014).

    NPP_h  =  npp0_h * capacity * fert * (1 + gamma_diff * AOD_h)

**Six sites, R and C++ twins kept in parity:**
- `R/cpp.R` — `aod_NH`, `aod_SH` appended LAST to `CCX_FORCING_COLS`; `gamma_diff` added to the
  marshalled parameter list and defaulted in `ccx_cpp_par()`.
- `R/forcing.R` — new `ccx_aod_at()` loader (zero outside coverage); columns emitted by
  `ccx_build_forcing()` and passed per-month by `ccx_forcing_at()`.
- `src/ccx_core.cpp` — `N_FORCING` 15 → **17**; `f[15]`/`f[16]` with the isfinite→0 absence
  contract; `P.gamma_diff`; the NPP multiplier.
- `R/model.R` — `gamma_diff = 0` default and the R twin of the NPP line.
- `tests/testthat/test-volcanic-diffuse.R` — four tests.

**⚠ `gamma_diff` DEFAULTS TO 0, DELIBERATELY.** The mechanism is OFF unless asked for, so **every
pre-2026-08-29 result is bit-identical and the calibrated 21 remain comparable.** Verified: the
logpost at `u_mode` is **−1546.276578**, unchanged. It is a `base_param` like `ent_seas_amp_SH`,
**not** a fitted parameter — making it the 22nd fitted parameter is a separate, explicit decision.

## 2. ⚠ THE BUG I MADE, AND THE TEST THAT NOW CATCHES IT

`src/ccx_core.cpp:52` carries `N_FORCING`, a hardcoded row width, and **its own comment says
"a disagreement in the ceiling is NOT caught by anything"**. I appended two columns and did not bump
it. `f[15]` and `f[16]` then read **past the row buffer** and returned adjacent memory:

    C++  gamma_diff 0 -> 327.9825 ; 2 -> 327.9821 ; effect -0.0004 ppm   <- garbage
    R    gamma_diff 0 -> 327.9825 ; 2 -> 323.8720 ; effect -4.1105 ppm   <- correct

**Nothing errored. No test failed. The effect was simply ~10⁴× too small.** R↔C++ parity caught it
(9.4 ppm gap) and nothing else would have. After the fix, parity is **4.5e-13 ppm** with the
mechanism ON. **The new test's third case is the mutation test for exactly this**: a non-zero
`gamma_diff` must MOVE the C++ answer — a test that only checked "0 changes nothing" would have
passed throughout the bug.

## 3. WHAT IT DOES — AND THE RESULT THAT MATTERS

Detrended interannual growth-rate anomaly, 1959–2023, at the mode's other parameters FROZEN:

| `gamma_diff` | 1992 (Pinatubo) | sd | **r** | Δlogpost (frozen) |
|---|---|---|---|---|
| 0 | +0.043 | 0.3006 | 0.571 | 0 |
| **0.25** | −0.466 | 0.3201 | **0.625** | −40.5 |
| **0.50** | −0.975 | 0.3648 | **0.625** | −160.8 |
| 0.75 | −1.485 | 0.4268 | 0.601 | −360.4 |
| 0.97 | **−1.934** | 0.4907 | 0.573 | −601.3 |
| 1.50 | −3.018 | 0.6643 | 0.514 | −1429.8 |
| **OBSERVED** | **−1.937** | **0.8996** | 1.000 | — |

**⇒ r RISES, 0.571 → 0.625, peaking at `gamma_diff` ≈ 0.25–0.50.** That is the first change in this
whole session that makes the model **MORE RIGHT** rather than merely louder — contrast
[[ccx_variability_gap]], where r was FLAT across an 11× ENSO range. **The mechanism is carrying real
signal.**

**⚠ AND THE TWO OPTIMA DISAGREE.** Matching the Pinatubo anomaly needs **`gamma_diff` ≈ 0.97**;
maximising the correlation wants **≈ 0.25–0.50**, a factor of 2–4 lower. Reproducing one FEATURE and
fitting the RECORD are different targets, and this is the second time today that distinction has
mattered (the first: ENSO's variance-matching vs squared-error-optimal amplitude).

## 4. ⚠ WHAT IS *NOT* ESTABLISHED — DO NOT ADOPT ON THIS

**The Δlogpost column is FROZEN, and frozen costs are UPPER BOUNDS.** This repo has been burned
reading them as prices — *"the refit recovered 15–19× more than the frozen scan predicted"*
(handoff 08-25b §7). A −40 at `gamma_diff` = 0.25 is **not** a price until a conditional refit says
so, and the obvious compensators (`beta_max`, `fert_k`, `luc_scale`) were all held here.

**A plausible mechanism for the frozen cost, untested:** the enhancement takes carbon into the land
pools and returns it over pool turnover times, so repeated eruptions across 1850–2024 leave a
CUMULATIVE level offset, and the CO₂ level rows (currently fitted to 0.53–0.58 ppm RMS, and
outvoting everything 40:1 — [[ccx_stream_leverage]]) would pay for it. **Untested: decompose the
frozen cost by stream before believing any story about it.**

**⇒ NEXT ON THIS ITEM: a conditional profile of `gamma_diff`** over 0–1 with a carbon slice free,
and a by-stream decomposition. Until then **nothing is adopted and `gamma_diff` stays 0.**

## 5. THE COVERAGE GAP THAT LIMITS THE PEDAGOGY

The AOD series starts in **1850**, so **Laki 1783, the 1808/09 unknown and TAMBORA 1815 are absent**
and a 1750-start run sees a volcanically silent first century. The largest eruption in the model's
whole window is therefore **Krakatau 1884**, not Tambora. **"The year without a summer" is not
available as a teaching story until eVolv2k is added.**
