# Handoff — CarbonCycleEmulator, 2026-08-13

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, branch `luc-veg-debit`
(= `ee0d914`, **still not merged**). Suite **400 pass / 4 fail / 2 skip** — the same four
failures as 12d, plus 12 new guard assertions.

Supersedes `handoff_2026-08-12d_frozen_land_bounded_kz.md` **on its §0 step 1 only**.
Steps 2 and 3 of 12d §0 stand unchanged and unstarted. Everything in 12d §§2–8 and §10
still applies — in particular **the defaults moved** (`kz` is 5000, not 4000) and
**freezing a parameter is a `CCX_PARAM_TABLE` deletion**.

---

## 0. START HERE

12d §0 said: fix the three σ's, then replace the `kz` bound with a deep-Δ¹⁴C likelihood
term, then bound `q10` if still needed. **That ordering was built on a mechanism that is
now measured to run the other way** (§1). Marcus' two decisions of 2026-08-12 stand
(§4), but the reason for step 1 has changed and one of them was taken on a premise that
is now false (§5).

**The one thing to settle before anything else runs:** what `sigma_d13c` is fixed at,
given that the δ¹³C residual carries a **0.55 ‰ bias the model structurally cannot
remove** (§2, §3). At the prior median 0.1 ‰ that bias is ~450 log-units of weight
pressing in the direction of `q10 < 1`. Marcus has already chosen "prior medians
1.5 / 0.1 / 5" — but partly on my statement that 0.1 would *become* the honest value once
the fossil source was fixed, and it did not. **Re-confirm or revise before editing
`CCX_PARAM_TABLE`.** See §5 for the three options as they now stand.

Everything else in 12d §0 is unaffected: the `kz` bound still leaks (12d §8), the
deep-Δ¹⁴C likelihood term is still the right replacement, and `q10` should still be
bounded last if at all.

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

## 3. Four candidates, one fixed, none sufficient

| candidate | measured | verdict |
|---|---|---|
| fossil source `d13c_foss` | −28 → −24 ‰ moves the bias +0.577 → +0.048, CO₂ unmoved | strong lever — **fixed**, worth **3 %** (§3a) |
| `alpha_photo`, `alpha_as_up`, `alpha_as_down` | 0.014–0.035 ‰ per ‰ | an order of magnitude too weak |
| sink partition (β scan) | closing δ¹³C needs a **72 % land share** vs GCB's 42 %; costs **+40 ppm** CO₂ and a 4.7 GtC/yr land sink vs GCB's 2.4 | δ¹³C and CO₂ cannot both be satisfied |
| gross land loop `ra_ratio` | **0.10 ‰** across 0→2; Δ¹⁴C goes **+2.7 → −14.6 ‰** over the same range | too weak, and ¹⁴C forbids the large values |

**Untested candidate, and the one I would take next: the ocean side.** The ocean is pure
diffusion with no biological pump and a DIC inventory ~16 % low (12d §4). Its ¹³C
disequilibrium flux is the one term in the atmospheric ¹³C budget nothing here has
probed. `alpha_as_up`/`alpha_as_down` probe the *fractionation*, not the *magnitude of
the gross exchange* or the *size of the reservoir it exchanges with* — those are `k_w`,
`h_ml` and the missing pump. A scan of `k_w × h_ml` against the δ¹³C bias, with CO₂ and
Δ¹⁴C carried alongside, is the analogue of diag [4] for the ocean and is ~20 model runs.

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

## 4. What that means for the q10 inversion

12d §7 called the whack-a-mole pattern the real finding and predicted that if `q10` still
railed after steps 1–2 that would be a **structural** result. **It is, and it can be
named now:** the model over-depletes atmospheric δ¹³C by ~0.55 ‰ and cannot be made not
to, so the calibration's only remaining relief is to manufacture land sink. `q10` → 0.169
is that relief. The mole has a burrow, not just a new hole each time.

This does not make `q10 = 0.169` acceptable — it makes it a *symptom with a located
cause*, which is a better thing to write in a communications model's documentation than
"the fit does something indefensible".

## 5. The σ decision, as it now stands

Marcus chose **prior medians 1.5 / 0.1 / 5** (2026-08-13). σ_co2 and σ_d14c are
uncontroversial: measured residual RMS at the mode is 0.85 ppm for CO₂ (so 1.5 is loose
and conservative) and the implied σ_d14c is 5–8 ‰.

**σ_d13c is the live one.** The choice was made partly on my statement that 0.1 ‰ would
become the *honest mismatch* value once the fossil source was fixed — the residual's
scatter around its bias is only 0.07 ‰. That premise is false: the 0.55 ‰ bias survives.

| option | consequence |
|---|---|
| **0.1 ‰ (prior median, as chosen)** | ~450 log-units of weight on a residual the model cannot remove, all of it pushing `q10` down. Defensible as "declare the error model up front and let the misfit show" — but expect `q10` to rail harder, and read that as the §4 finding, not a new pathology. |
| **~0.45 ‰ (measured mismatch)** | Honest about today's discrepancy; keeps δ¹³C from dominating. Bakes a known structural defect into the error model and permanently downweights the land/ocean separator. This is what the free fit chose on its own (0.440). |
| **0.1 ‰ + an explicit δ¹³C offset term** | Score the *shape* of the Suess decline and let a nuisance offset absorb the level. Costs one parameter, keeps δ¹³C's partition information, and stops the bias masquerading as a land-sink signal. Not implemented; not discussed with Marcus. |

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
| `ee0d914` | CHANGELOG |

## 8. Opening the next session

```bash
cd ~/Documents/2026/CodeProjects/CarbonCycleEmulator && claude --remote-control ccx-dev
```

> Read `notes/handoff_2026-08-13_d13c_structural_misfit.md`, then
> `notes/handoff_2026-08-12d_frozen_land_bounded_kz.md` for §§2–8 and §10, on branch
> `luc-veg-debit`. Settle §5 (σ_d13c) with Marcus first. Then either take §3's untested
> ocean-side candidate, or run 12d §0 steps 1–2 as written — predicting, per §1, that
> `q10` gets worse rather than better.
