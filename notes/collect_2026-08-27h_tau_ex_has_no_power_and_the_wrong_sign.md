# COLLECT 27h — **FORK (a) IS A GUARANTEED NULL. `tau_ex` HAS NEITHER THE PRICE NOR THE SIGN.**
# The NH import is not causing the SH-land overshoot — it is partly HIDING it

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, trunk `main`.
**Decision it answers:** handoff `notes/handoff_2026-08-27h_the_blocker_moved_to_sh_land.md` §4,
fork **(a)** — "pre-register and run the seasonal block **plus `tau_ex`**". Marcus chose (a)
2026-08-27.

**⇒ THE PRE-CHECK KILLED THE TEST BEFORE IT WAS WRITTEN, AND THAT IS THE RESULT.**
The wider slice was NOT run. The 40-minute refit would have returned "P3 still FAILED" for reasons
that have nothing to do with the physics it was built to test.

---

## 0. WHAT WAS ASKED, AND WHY IT WAS PRE-CHECKED INSTEAD OF RUN

Handoff 27h §4 argued that 27g's **P3 FAILED** may be an artefact of the SLICE, not of the model:
the P2 slice froze `tau_ex`, the only *fittable* lever on the **0.821 ppm** of SPO's seasonal cycle
that arrives from the NH, and SH land at SPO is ~2× observed. Good hypothesis.

But its null was at risk of being **structurally guaranteed**. If the interhemispheric rows pin
`tau_ex` to a few per cent, "we freed `tau_ex` and P3 still failed" and "we never freed it" produce
the same output, and neither is evidence. So the POWER was measured first. [[no_power_null]]

**THIS IS THE SECOND HALF OF 27e, NOT A RE-DERIVATION OF IT.**
`calibration/diag_tau_ex_leak_profile.R` (prereg 27e) already profiled `tau_ex` and **exonerated it
as a PARTITION lever** — the SPO δ¹³C-per-ppm ratio moves 4.2 % across a 5.7× range, because both
parts of the model's SPO cycle carry the LAND signature, so transport relabels *where* the cycle
was made rather than *what* made it. Handoff 27h §4 accepts that and says the binding error is one
of **SIZE**, which 27e explicitly did not settle. Answering the size question needs three things
27e's own header says it lacks: it is **frozen in the other 20 parameters** and calls every cost an
overstatement; it reads the **ratio**, not the component **amplitudes**; and it names the frozen
`grad_off_co2` as an unremoved caveat. All three are removed below.

Two new diagnostics, both committed:

    Rscript calibration/diag_tau_ex_seasonal_power.R       # ~12 min, 15-point profile
    Rscript calibration/diag_tau_ex_conditional_power.R    # ~35 min, conditional profile

plus the existing inversion re-run at two `tau_ex` values via `CCX_PAR_RDS`.

---

## 1. THE THREE FINDINGS, IN ASCENDING ORDER OF FORCE

### (i) PRICE — `tau_ex` is pinned to ~2.6 % per log-unit

The profile (every other parameter at the mode, the two gradient OFFSETS re-optimised at each
point, since those exist precisely to absorb the station-latitude representation constant):

| τ/τ₀ | τ_ex | Δlogpost | NH import at SPO |
|---|---|---|---|
| 0.79 | 0.916 | −79.4 | 1.010 |
| **1.00** | **1.159** | **0** | **0.821** |
| 1.09 | 1.263 | −11.2 | 0.759 |
| 1.26 | 1.460 | −77.0 | 0.665 |
| 2.00 | 2.318 | −750.9 | 0.429 |
| 4.00 | 4.636 | −4528.9 | 0.219 |

Read at the budgets the 27g challenger actually banked (**+11.62** net = +16.78 prior − 5.17
likelihood):

| budget | τ_ex reachable | NH import | % of mode |
|---|---|---|---|
| 2.00 | 1.198 (1.034×) | 0.797 | 97 % |
| 5.00 | 1.226 (1.057×) | 0.781 | 95 % |
| **11.62** | **1.265 (1.092×)** | **0.758** | **92 %** |

**Exchange rate: 0.0054 ppm of NH import removed per log-unit spent.** The entire 27g gain buys
**0.063 ppm** against an SPO land excess of ~0.70 ppm — **9 % of the gap**.

**The 1/τ law is verified, not assumed.** The measured import tracks the analytic two-box gain
`(1/τ)/√(ω²+1/τ²)` to within 2–6 % across a 8× range in τ (at 1.26×: predicted 0.796, actual
0.809; at 4.00×: 0.252 vs 0.266). So the lever really is transport-limited and the law is the
right model of it.

**A PROFILE IS ONLY A LOWER BOUND, so it was checked conditionally.** [[profile_beats_optimum]]
`diag_tau_ex_conditional_power.R` fixes `tau_ex` and re-optimises the WHOLE 27h slice around it —
the six 27g seasonal parameters plus both gradient offsets, eight free, warm-started by
continuation and restarted until the improvement dies (all points converged, last gain 0.0000):

| τ/τ₀ | conditional cost | profile cost | buy-back | NH import | SPO total |
|---|---|---|---|---|---|
| 1.00 | 0 | 0 | — | 0.821 | 1.138 |
| 1.12 | **−12.75** | −19.06 | 0.67× | 0.742 | 1.105 |
| 1.26 | **−53.93** | −77.01 | 0.70× | 0.667 | 1.074 |

**The slice buys back ~30 % of the profile's cost and does not change the verdict.** At the local
rate near the budget (0.0062 ppm/log-unit), the whole +11.62 buys **0.072 ppm** — ~10 % of the
0.699 ppm excess. And the 1.26× point is **bought, not earned**: `grad_off_co2` lands at
**−0.827 ppm** (prior z −1.65), past the measured station-latitude constant of −0.386/−0.549 ppm,
i.e. the offset is absorbing model error rather than representing a latitude.

⚠ The FIRST run of that script hit `maxit` at all three points and was **DISCARDED**. An
under-converged optimum at fixed `tau_ex` reports that `tau_ex` as costlier than it is — it
manufactures exactly the verdict the script exists to test. The convergence fix (continuation
warm-start + BFGS polish + restart-until-still) and a printed restart/last-gain column are in the
committed version so a silent `maxit` cannot recur.

### (ii) INVARIANCE — at ANY price, `tau_ex` does not move the SPO cycle

Over the whole 8× grid, at SPO:

| component | at τ₀ | at 4.00 τ₀ | change |
|---|---|---|---|
| NH-origin | 0.821 | 0.219 | **−73 %** |
| **SH-LOCAL land** | **1.308** | **1.331** | **+1.7 %** |
| SPO total | 1.141 | 1.121 | −1.7 % |

`tau_ex` **reallocates** SPO's cycle between NH-origin and SH-local. It does not shrink it. The
SH-local land channel — dominated by `seas_npp_amp_SH`, **a measured constant that is not fittable
at all** — is untouched.

### (iii) SIGN — and this is the one that ends it

Re-run in the **handoff's own estimator**, the signature inversion, at two `tau_ex` values:

| SPO (inversion) | τ = 1.159 | τ = 4.636 (−4529 log-units) |
|---|---|---|
| model land | 1.373 @ 8.82 | **1.401 @ 10.02** |
| obs land | 0.683 | 0.676 |
| **land ratio** | **2.01×** | **2.07×** |
| model ocean | 0.236 @ 3.35 | 0.274 @ 4.01 |
| ocean ratio / phase err | 0.45× / −5.17 mo | 0.52× / −4.51 mo |

**Quadrupling `tau_ex` makes the SPO land overshoot WORSE.** Not merely underpowered — the wrong
sign on the target quantity.

**The mechanism is the phases.** NH-origin peaks at month **6.47**, SH-local land at **10.09** —
**108° apart**, so they partially CANCEL in the land-signatured resultant. Removing the NH part
removes the cancellation.

> **⇒ THE NH IMPORT IS NOT CAUSING THE SH-LAND OVERSHOOT. IT IS PARTLY HIDING IT.**

⚠ The inversion's *observed* land moves too (0.683 → 0.676, −1 %), because the inversion inverts
the observed harmonics through the MODEL's channel signatures `s_L`/`s_O`, which move with
`tau_ex`. It is small and the 2.01 → 2.07 conclusion survives it, but the "observed" component is
not purely observational and should not be quoted as if it were.

⚠ The handoff §4 quotes the observed SPO land as **0.665**; the inversion measures **0.683** at the
mode. Both runs here report 0.676–0.683. The ratios above use the measured value.

---

## 2. WHAT PINS `tau_ex`, AND IT IS NOT THE SEASONAL CYCLE — a standing note needs qualifying

`R/likelihood.R:175` says **"66 % of `tau_ex`'s leverage came from the seasonal harmonics"**. That
was written 2026-08-15, *as the justification for adding* the interhemispheric-gradient term. It is
now only half true, and the half that fails is the half that matters here.

Cost decomposition at 1.26 τ₀ (offsets re-optimised), the direction that would shrink the import:

| row | Δ |
|---|---|
| `d13c_level_MLO` | −20.43 |
| `d13c_level_SPO` | −14.44 |
| `d14c_NH` | −12.06 |
| `co2_level_MLO` | −9.54 |
| `d14c_SH` | −7.98 |
| `co2_gradient` | −7.49 |
| **four seasonal rows, net** | **−3.40** (and `co2_seasonal_SPO` **improves** +9.74) |

**Upward, the bill is annual-mean isotopes and levels — the seasonal rows barely object, and the
SPO one actively wants it.** Downward it is still seasonal, and overwhelmingly so: at 0.79 τ₀,
`co2_seasonal_SPO` −57.00 and `co2_seasonal_MLO` −28.31 carry the cost.

So `tau_ex` sits in a two-sided vice with a *different jaw on each side*, and the note's "66 %"
describes only the lower jaw.

---

## 3. WHAT WAS **NOT** DONE, AND WHY

- **The wider slice was not run.** Its result is predictable from the above and would not be
  evidence. Running it and reporting "P3 FAILED again" would be a null with no power dressed as a
  finding.
- **No prereg was written for it.** A pre-registration whose falsifier cannot fire is not a
  pre-registration.
- **Nothing in the model was changed.** Two diagnostics added; `R/` and `src/` untouched.
- **27e is not contradicted, and neither is 27h §4's arithmetic.** `tau_ex` really does carry the
  0.821 ppm; §4's sums are right. What is new is that the term is (a) unaffordable to move, (b)
  inert on the SPO total, and (c) *stabilising* the land ratio rather than inflating it.

---

## 4. ⇒ THE DECISION NOW OWED

The blocker has moved again, and it is now specific: **the SH-LOCAL land channel at SPO is ~2×
the observed land component, and `seas_npp_amp_SH` — its dominant term, 1.390 ppm at SPO against
`resp SH`'s 0.092 — is a MEASURED CONSTANT that no fit can touch.** Three ways that can be true,
and they need different work:

- **(A) The measured constant is wrong**, or the phi_eff/insolation mapping that sets it is. See
  [[ccx_phi_eff_amplitude]] — LATITUDES right, AMPLITUDE not; a free amplitude bought 34 %. This is
  the cheapest and the most likely.
- **(B) The channel is right and the OBSERVED comparator is wrong.** The inversion's observed land
  is model-signature-dependent (§1 iii) and its bar is wide: 0.676 [0.474, 0.908]. 2.07× against
  the upper bar is 1.54×.
- **(C) The NH box's own seasonal amplitude is too big**, and the import is a symptom.
  `R/likelihood.R:1091` maps `co2_NH` straight onto MLO and `:1178` scores its harmonic with a
  LEVEL offset and **no amplitude representation term** — the model asserts MLO's cycle IS the NH
  hemispheric mean. Still the cheapest unchecked item (handoff 27h §7), and NOAA's network measures
  it. ⚠ But note the direction: the NH hemispheric mean is *larger* than MLO, so correcting this
  makes the NH box BIGGER and the import WORSE. It is worth doing to know, not as a fix.

**Marcus's call.** My recommendation is **(A)**, and to do it as a POWER check first — profile
`seas_npp_amp_SH` against the SPO land ratio exactly as `tau_ex` was profiled here — before any
refit is designed around it. That pre-check is ~15 minutes and it is what would have saved the
40 minutes today.
