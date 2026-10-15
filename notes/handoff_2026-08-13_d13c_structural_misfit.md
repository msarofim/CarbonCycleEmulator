# Handoff — CarbonCycleEmulator, 2026-08-13

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, branch `luc-veg-debit`
(= `9aa0097`, **still not merged**). Suite **400 pass / 4 fail / 2 skip** — the same four
failures as 12d, plus 12 new guard assertions.

Supersedes `handoff_2026-08-12d_frozen_land_bounded_kz.md` **on its §0 step 1 only**.
Steps 2 and 3 of 12d §0 stand unchanged and unstarted. Everything in 12d §§2–8 and §10
still applies — in particular **the defaults moved** (`kz` is 5000, not 4000) and
**freezing a parameter is a `CCX_PARAM_TABLE` deletion**.

---

## 0. START HERE

12d §0 said: fix the three σ's, then replace the `kz` bound with a deep-Δ¹⁴C likelihood
term, then bound `q10` if still needed. **That ordering was built on a mechanism that is
now measured to run the other way** (§1). Marcus' two decisions of 2026-08-12 stand (§4).

**Two things happened this session, and the second changes what the first means.**

1. The δ¹³C residual carries a **0.55 ‰ bias** that grows monotonically and is not
   removable by the fossil source signature, the fractionation constants, the reachable
   sink partition, or the gross land loop (§2, §3). It pushes `q10` **down**, so it is a
   contributor to the inversion rather than the cure step 1 assumed.
2. **It is now explained** (§3b): the bias is the price of the pure-diffusion ocean. The
   only lever that closes it is `k_w`, at 2.7× the Wanninkhof global mean, and the reason
   is the missing overturning — the same gap the ¹⁴C budget residual already pointed at
   in 12d §2. This is a **chosen** DESIGN §2 limitation, now priced in per mil.

**The one thing to settle before anything else runs:** what `sigma_d13c` is fixed at.
Marcus chose "prior medians 1.5 / 0.1 / 5" on 2026-08-13, partly on my statement that
0.1 ‰ would *become* the honest value once the fossil source was fixed. It did not. With
§3b in hand the question is no longer "how big is the unexplained residual" but **"where
in the model does a known ventilation gap belong"** — see §5, where the three options are
re-argued and one is recommended. Marcus asked for that comparison and **has not yet
decided. Do not edit `CCX_PARAM_TABLE` until he has.**

`sigma_co2` and `sigma_d14c` are not in question: 1.5 and 5 both stand (§5).

Everything else in 12d §0 is unaffected: the `kz` bound still leaks (12d §8), the
deep-Δ¹⁴C likelihood term is still the right replacement, and `q10` should still be
bounded last if at all — and §3b is now a reason to think harder before bounding it,
since part of what drives it is a limitation we chose.

---

## 1. Step 1's premise was backwards — measured, not argued

12d §0 step 1 held that the fit loosens `sigma_d13c` to escape "the one term that would
discipline the land sink". `calibration/diag_q10_stream_direction.R` scans `q10` with
everything else held, at fixed σ's, and reports `ccx_loglik(by_stream = TRUE)`. Relative
to `q10 = 2.0`, moving to `q10 = 0.2`:

| stream | at defaults | at the 16-par mode's other parameters |
|---|---|---|
| `d13c_level_MLO` | **+254.4** | **+345.8** |
| `d13c_level_SPO` | **+157.6** | **+293.5** |
| `co2_level_MLO` | −1533.6 | +1169.8 |
| `co2_level_SPO` | −1605.0 | +1082.0 |

**δ¹³C prefers the lower `q10` at both parameter vectors.** Tightening `sigma_d13c`
strengthens the force behind the inversion. Step 1 is still worth running — fixing the
σ's removes the fit's ability to choose its own targets, which is right on its own terms
— but **predict `q10` getting worse, not better**, and do not read a worse `q10` as the
step having failed.

Note also what the CO₂ rows show: the sign of the CO₂ pull **flips** between the two
parameter vectors. At defaults CO₂ wants high `q10`; at the mode's other parameters
(β = 0.088, k_w = 1697, h_ml = 178) it wants low. β and `q10` are trading off along a
constant-sink direction, and something else is breaking the tie. §3 is that something.

## 2. The δ¹³C residual: shape right, magnitude ~30 % too steep

`calibration/diag_d13c_suess.R` [1]. obs − model, MLO annual levels:

```
1850-1899  -0.035     1980-1984  +0.358      2010-2014  +0.540
1900-1929  +0.001     1990-1994  +0.412      2015-2019  +0.551
1950-1959  +0.113     2000-2004  +0.422      2020-2024  +0.561
```

Monotonic growth, 0.07 ‰ of year-to-year scatter around it. Not noise, not a constant
offset — the model reproduces the Suess decline's shape and overshoots its magnitude.
Observed 1850 → 2020 is −1.89 ‰; the model gives −2.50 ‰.

## 3. Six candidates: one fixed, one explains it, none is available

| candidate | measured | verdict |
|---|---|---|
| fossil source `d13c_foss` | −28 → −24 ‰ moves the bias +0.577 → +0.048, CO₂ unmoved | strong lever — **fixed**, worth **3 %** (§3a) |
| `alpha_photo`, `alpha_as_up`, `alpha_as_down` | 0.014–0.035 ‰ per ‰ | an order of magnitude too weak |
| sink partition (β scan) | closing δ¹³C needs a **72 % land share** vs GCB's 42 %; costs **+40 ppm** CO₂ and a 4.7 GtC/yr land sink vs GCB's 2.4 | δ¹³C and CO₂ cannot both be satisfied |
| gross land loop `ra_ratio` | **0.10 ‰** across 0→2; Δ¹⁴C goes **+2.7 → −14.6 ‰** over the same range | too weak, and ¹⁴C forbids the large values |
| land **lag** — `tau_wood`, `tau_soil_slow`, `litter_slow_frac`, `npp_veg_frac` | every value that helps costs **15–50 ‰** of Δ¹⁴C (`tau_wood` 150 → +43.8; `litter_slow_frac` 0.5 → +51.5) | ¹⁴C forbids all of it |
| **ocean `k_w`** | 1500 → 4000 m/yr: bias **+0.548 → +0.075 ‰** for ~2 ppm of CO₂, Δ¹⁴C and land share untouched | **the lever — and unphysical** (§3b) |
| ocean `h_ml`, `kz` | `h_ml` moves it 0.085 ‰ across 30–200 m; `kz` 10,000 helps but costs +13 ppm and +22 ‰ Δ¹⁴C | not it |

Rows 1–4: `calibration/diag_d13c_suess.R`. Rows 5–7: `calibration/diag_d13c_levers.R`.

### 3a. The fossil-source fix — right, and a falsified prediction

`d13c_foss` was a single **−28 ‰ applied from 1750 to 2024**, held in `ccx_prepare()`'s
aux. Wrong twice over, both in the same direction:

- GCB's `fossil` column is fossil-fuel-**and-industry**, so ~4–5 % of it is **cement** —
  calcined limestone at ~0 ‰, not fuel at −28.
- the fuel mix is not constant: all-coal (~−24 ‰) early, gas (~−44 ‰) modern.

Now built per year in `data-raw/build_calibration_data.R` **[5b]** from GCB 2025's own
by-fuel split (`gcb2025_fossil_emissions_by_fuel.csv`, new in MANIFEST), weighted by
citable endmembers: **coal −24, oil −26.5, gas −44, cement 0, flaring −44** (Graven,
Keeling & Rogelj 2020, GBC 34 e2019GB006170; Tans 1981 / Andres, Marland, Boden & Bischof
2000 for the crude-petroleum and gas modes, quoted in Bush, Pataki & Ehleringer 2007,
Appl. Geochem. 22:715–723). Series runs **−24.0 (1850) → −28.3 (2024)**, landing on both
ends of the −28 to −24 ‰ envelope Graven et al. state for the global signature.

**I predicted this would explain the overshoot. It moved the bias 0.577 → 0.561 ‰.**
Emission weighting is why: the years where the old constant was most wrong carry almost
no emissions, so a 4 ‰ sensitivity converts into a 0.016 ‰ correction. The scan measured
a counterfactual (the whole history at −24) the real fuel mix cannot deliver. The
correction stays — it was wrong twice over and is now right — but it is not the cause.

### 3b. The explanation: it is the price of the pure-diffusion ocean

`calibration/diag_d13c_levers.R`, the ocean analog of the `ra_ratio` test. `k_w` is the
only lever found anywhere that is not paid for somewhere else:

| k_w (m/yr) | δ¹³C bias | CO₂ bias | Δ¹⁴C bias | land share |
|---|---|---|---|---|
| 1500 (default) | +0.548 | +2.33 ppm | +2.65 ‰ | 46 % |
| 2500 | +0.259 | +3.63 | +4.59 | 46 % |
| **4000** | **+0.075** | +4.38 | +1.52 | 45 % |
| 6000 | −0.034 | +4.81 | −1.62 | 45 % |

**And it is not available.** 1500 m/yr *is* the Wanninkhof global-mean CO₂ transfer
velocity the prior is centered on (DESIGN.md line 102; ~16.5 cm/hr = 1450 m/yr). 4000 is
2.7× it, **+2.45 σ**. So the model needs 2.7× more gross air-sea exchange than a real
piston velocity delivers.

**Why, and it is not the piston velocity's fault.** The real ocean maintains its isotopic
disequilibrium by *circulation*: upwelling continually presents water last in contact
with a preindustrial atmosphere, so the flux returning to the atmosphere stays
isotopically old and damps the atmospheric decline. A pure-diffusion column has no
upwelling — it smears the Suess signal downward, the water at the surface has already
been partly loaded, and the return flux is too depleted. Raising `k_w` fakes the damping
by talking faster to a reservoir that is too equilibrated; raising `kz` fakes it by
burying the signal, at +13 ppm and +22 ‰ Δ¹⁴C by `kz` = 10,000. Note that `h_ml` moving
the bias only 0.085 ‰ across 30–200 m is the tell: it is **not** a reservoir-size problem,
it is a rate-of-renewal problem.

**Two isotopes, one gap.** 12d §2 closed the ¹⁴C budget with the residual "atmosphere
short / ocean long ⇒ **ventilation**". This is that same missing term seen in δ¹³C.
DESIGN §2 rejected HILDA as "too many parameters to communicate" and 12d §10 lists ocean
advection among the deliberate omissions — so this is a **known, chosen limitation now
priced at ~0.55 ‰**, not a new defect. For a model whose job is communication, being able
to say *that* about itself is a better outcome than a closed residual would have been.

If it is ever revisited, the cheapest structural candidate is not full HILDA but a single
prescribed upwelling velocity through the column (one parameter, one number a reader can
be told). Nothing here has costed that; it is a suggestion, not a plan.

## 4. What that means for the q10 inversion

12d §7 called the whack-a-mole pattern the real finding and predicted that if `q10` still
railed after steps 1–2 that would be a **structural** result. **It is, and it now has a
name and an address:** the model over-depletes atmospheric δ¹³C because its ocean cannot
maintain the isotopic disequilibrium, and the calibration's only remaining relief is to
manufacture land sink. `q10` → 0.169 is that relief.

That does not make `q10 = 0.169` acceptable. It makes it a *symptom with a located cause*,
which changes what to do about it: bounding `q10` to [1, 4] (12d §0 step 3) would now be
clamping a symptom of a limitation we chose deliberately, and the bound would be doing
work the documentation should be doing. Take that into account when step 3 comes up —
the honest artifact may be a bounded `q10` **plus** a stated ventilation caveat, not one
or the other.

## 5. The σ decision — re-argued with §3b in hand, and NOT yet taken

Marcus chose **prior medians 1.5 / 0.1 / 5** on 2026-08-13, then asked for the pros and
cons re-stated once the other fixes had been explored. That comparison is below; **he has
not come back on it.** `sigma_co2` and `sigma_d14c` are settled either way — measured CO₂
residual RMS at the mode is 0.85 ppm (so 1.5 is loose and conservative) and the implied
σ_d14c is 5–8 ‰.

The framing changed with §3b. The question is no longer "how large is the unexplained
residual" but **"where in the model does a known, chosen ventilation gap belong"**.

| option | pro | con |
|---|---|---|
| **0.1 ‰** (prior median, as chosen) | Declared up front, no post-hoc widening; the misfit stays visible in the by-stream diagnostics rather than being absorbed. | ~450 log-units on a residual the model cannot remove, all of it pushing `q10` down — buying an indefensible `q10` with a limitation we chose. The 0.07 ‰ scatter that makes 0.1 tempting is the **shape** residual, and the shape is not what is biased. |
| **0.45 ‰** (measured mismatch) | Stops the bias masquerading as a land-sink signal; it is also what the free fit chose unprompted (0.440), so fit and diagnosis agree. | Permanently downweights the constraint δ¹³C was added for, and encodes a ventilation gap as a δ¹³C *measurement* error — the wrong place for it unless the comment says otherwise. |
| **0.1 ‰ + a δ¹³C nuisance term** | Scores the shape (which the model gets right) and lets the level go, keeping the partition information. | **Weakened since it was first proposed:** the bias *grows* (+0.001 in 1900–29 → +0.561 in 2020–24), so a constant offset fits it badly. The honest form is a scale on the Suess amplitude, which is "the ocean damping is X % too weak" wearing a nuisance parameter's clothes. |

**Recommended: 0.45 ‰, with the reason written into `CCX_PARAM_TABLE`** — not as
measurement error but as *"model-structural error from the missing ocean ventilation,
measured at 0.55 ‰ by `diag_d13c_levers.R`"*. It is the only option where the number has a
stated physical cause and a diagnostic that regenerates it, and it leaves `q10` to be
judged on its own evidence rather than on a ventilation gap. Marcus' call.

## 6. Mechanics worth knowing before touching this

- **The forcing table has a 10th column.** `CCX_FORCING_COLS` in `R/cpp.R` is the
  positional contract with `src/ccx_core.cpp`, which reads `f[9]`. A reorder is silent
  garbage, not an error; `test-forcing.R` gates the order and the length.
- **`ccx_forcing_d13c_foss()`** returns 0 for a hand-built zero-emission forcing (the
  spinup's, the conservation tests') and **errors** for one carrying emissions without a
  signature. Hand-built forcings with emissions — `test-parity.R` has two — must now
  state `d13c_foss`.
- **A diagnostic went inert and looked live.** diag [2]'s fossil scan overrode
  `aux$d13c_foss`, which stopped existing the moment the value moved to the forcing; it
  printed six identical rows. It now overrides the forcing column. Same failure class as
  the ¹⁴C decay gate (memory `feedback_mutation_test_your_gates`) — when a value moves
  between layers, re-check every diagnostic that pokes at it.
- **`data/forcing_emissions_historical.rds` gained a `d13c_foss` column.** Re-running
  `data-raw/build_calibration_data.R` reproduces every other `data/*.rds` **bit-identically**
  (checked), so that rebuild is safe.
- SSP and caller-supplied pathways carry no `d13c_foss`; the last historical value is
  **held flat**, the same convention the GMST column uses. δ¹³C is not scored past 2024.

## 7. Commits

| | |
|---|---|
| `f7213dd` | Two diagnostics: the δ¹³C Suess overshoot, and which stream drives q10 down |
| `8e44533` | Time-varying fossil-source δ¹³C, and the Suess overshoot is structural |
| `ee0d914` | CHANGELOG: the overshoot is structural; step 1's premise was backwards |
| `c765321` | diag_d13c_levers.R — the overshoot is the price of the pure-diffusion ocean |
| `9aa0097` | CHANGELOG: k_w is the lever and it is unphysical; the gap is ventilation |

## 8. Opening the next session

```bash
cd ~/Documents/2026/CodeProjects/CarbonCycleEmulator && claude --remote-control ccx-dev
```

> Read `notes/handoff_2026-08-13_d13c_structural_misfit.md`, then
> `notes/handoff_2026-08-12d_frozen_land_bounded_kz.md` for §§2–8 and §10, on branch
> `luc-veg-debit`. §5 is open and blocking: get Marcus' call on `sigma_d13c` before
> touching `CCX_PARAM_TABLE`. Then run 12d §0 steps 1–2 — predicting, per §1, that `q10`
> gets worse rather than better, and reading §3b before deciding what step 3 should be.
