# COLLECT 2026-08-28 — **THE 236-LOG-UNIT PULL DOES NOT EXIST. THE CLIFF IS THE WHOLE STORY.**
# H2 fails — the bound IS load-bearing — but what it bears is the FREE LUNCH, not physics.

**Prereg:** `notes/prereg_2026-08-28_hml_unbound_profile.md`, committed **`805e8c4` BEFORE** the
driver. **No gate moved.** Driver `calibration/diag_hml_unbound_profile.R`, output
`outputs/diagnostics/hml_unbound_profile.rds`. **`R/` and `src/` untouched; no objective changed and
no refit is owed.** 26 points, all converged (1 restart, gain 0.0000), 83–241 s each.

    H1 ✓   H2 ✗   H3 ✗   H4 ✗

---

## 1. THE PROFILE

`h_ml` fixed, `beta_max` / `fert_k` / `k_w` / `kz` / `pump_grad` re-optimized at every point, over
the **SHIPPED** [30, 200] rather than the refit's [85, 120].

| `h_ml` | rows | Δ logpost | `kz` (% up bracket) | `pump_grad` |
|---|---|---|---|---|
| 198 | off | +3.19 | 57.7 % | 446.3 |
| 160 | off | +6.02 | 72.3 % | 396.7 |
| 126 | off | +6.91 | 83.6 % | 333.8 |
| **120.01** | off | **+7.03** | 85.4 % | 324.0 |
| 119.99 | LIVE | −1.40 | 88.1 % | 273.4 |
| 104 | LIVE | −0.35 | 91.2 % | 270.5 |
| **96.47 (mode)** | LIVE | **+0.00** | 92.4 % | 269.2 |
| 88 | LIVE | +0.28 | 93.7 % | 267.8 |
| **85.01** | LIVE | **+0.35** | 94.1 % | 267.3 |
| **84.99** | off | **+7.65** | 93.8 % | 274.6 |
| **75** | off | **+7.74 ← ARGMAX** | 95.3 % | 263.0 |
| 55 | off | +7.34 | 97.1 % | 244.6 |
| 38 | off | +5.35 | 97.9 % | 230.7 |
| **32** | off | **+3.17** | 98.2 % | 226.0 |

**Three facts, and the third is the finding:**
1. **In-band the objective is FLAT** — +0.00 → +0.35 across 11.5 m, consistent with `h_ml`'s 1σ of
   ~11 m. The in-band optimum is at the *shallow* end; going deeper costs (−1.40 at 119.99).
2. **The cliff is −7.300 at 85** and **+8.426 at 120**.
3. **BEYOND THE CLIFF THERE IS +0.09 OF PULL** (84.99 → 75, the argmax), after which the profile
   **DECLINES**. **32 m is 4.57 log-units WORSE than 75 m.**

## 2. ⇒ 08-16g's "ARGMAX 32 m, PULL 236" DOES NOT REPRODUCE

That measurement — argmax at the prior bound with a **236 log-unit** pull against a **10.0** cliff,
**24×** — was made with **19 parameters FROZEN**. With the five uptake parameters free:

    argmax 75 m (not 32) | pull beyond the cliff 0.09 (not 236) | 32 m is 4.57 WORSE than 75

The refit had *suggested* the 236 was an artifact (h_ml landed interior at 96.47, not pinned at 85).
**It is now measured.** And because 5 free is conservative and one-way — the pull exists because
`h_ml` patches a misfit the uptake set serves directly, so freeing more can only reduce it — **this
generalizes to the full 20.**

## 3. THE CLIFF *IS* THE THREE ROWS, TO 0.3 %

    h_ml 84.9900 ( off): dic  skipped  d13c  skipped  alk  skipped   sum 0 (FREE)
    h_ml 85.0100 (LIVE): dic   -4.293  d13c   +1.248  alk   -4.231   sum -7.275
    h_ml 96.4737 (LIVE): dic   -4.254  d13c   +1.210  alk   -4.261   sum -7.305
    h_ml 119.990 (LIVE): dic   -4.191  d13c   +1.077  alk   -4.332   sum -7.446
    h_ml 120.010 ( off): dic  skipped  d13c  skipped  alk  skipped   sum 0 (FREE)

**At the lower edge the rows sum to −7.275 against a measured cliff of −7.300 — 0.3 %.** The cliff
is not *like* the free lunch; it **is** the free lunch, to within a rounding error. At the upper
edge the rows sum −7.446 against a cliff of +8.426, so **~1.0 log-unit there is re-optimization
freedom** (`pump_grad` jumps 273.4 → 324.0 once the rows stop constraining it) on top of the rows.

**⇒ H2 FAILS AND THE BOUND IS LOAD-BEARING — BUT 7.30 OF THE 7.39 ADVANTAGE AT THE ARGMAX IS THREE
SKIPPED GAUSSIANS.** The objective does not prefer a shallower mixed layer. It prefers **being
scored on less data**. That is defect (B), isolated and quantified.

## 4. H3 AND H4 BOTH FAIL, AND H3 INVERTS

- **H3 ✗, with the sign reversed.** `kz` does **not** come off its rail below the band — it is
  pushed **harder** onto it, 92.4 % → **98.2 %** at 32 m. It releases only going *deeper*
  (85.4 % at 120 → **57.7 %** at 198). So `kz` and `h_ml` are coupled, but the bound is **not**
  propping `kz` up; a shallower mixed layer drives `kz` into its ceiling. **My hypothesis had the
  sign backwards.**
- **H4 ✗.** `pump_grad` stays **226–446** with the rows off, never near 08-16g's 963.6 / 1431.0.
  ⚠ **This does NOT refute those** — they came from truncated refit arms with many more parameters
  free. It says the "rows off ⇒ `pump_grad` unconstrained" effect **needs more freedom than the
  uptake set to appear**, and that within this slice the rows are not the only thing identifying it.

## 5. WHAT IT MEANS FOR THE OPTION CHOICE — INCLUDING THE PART THAT DOES *NOT* FAVOR OPTION 5

**It strengthens the case for σ-inflation and says exactly what inflation must do:** charge for the
−7.275 the skip currently gives away free. A hard bound suppresses the symptom by making the region
unreachable; inflation removes the cause.

⚠ **BUT THE ARITHMETIC SAYS INFLATION AS PRICED DOES NOT FULLY CLOSE IT.** 08-16g measured a **21 %
residual** — inflation recovers 79 % of the skip's gain. Applied to the measured 7.30: residual
≈ **1.53**, so the out-of-band argmax would fall from +7.74 to **≈ +2.0** against an in-band +0.35.
**The pull drops from 7.39 to ~1.6 log-units — an 80 % reduction, not elimination.** ~1.6 is small
(the refit's own restart noise floor was ~0.7) but it is not zero, and **it is directional: the
argmax would still sit just outside the band.**

⚠ **AND THAT 21 % IS OBSERVATION-SIDE ONLY** — the file says so explicitly; it has never been
measured with the model's own gradient included. **This profile now makes the proper measurement
cheap and well-posed: re-run these same out-of-band points with inflation ON and read the argmax
directly, instead of scaling a number measured in another configuration.** That is the next step,
and it is the one that would let option 5 be adopted on a measurement rather than an inference.

## 6. TWO PROCESS DEFECTS THIS RUN PRODUCED, BOTH MINE

- **A reporting bug destroyed 45 minutes of fits.** The ocean-gradient table errored and `saveRDS`
  came *after* it. **The artifact is now written BEFORE any pretty-printing.**
- ⚠ **I walked into a trap this project has already documented.** `ccx_loglik(by_stream = TRUE)`
  returns a **named numeric VECTOR**, so `s[["absent_name"]]` **errors** rather than returning NULL
  — recorded verbatim in memory `ccx_hml_band_discont`. I wrote `is.null(s[[n]])`, which evaluates
  it first. Test **membership**, never nullity. That is the second documented trap I have hit this
  session. [[explained_away_test]]
