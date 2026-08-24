# Handoff — CarbonCycleEmulator, 2026-08-23c: the mid-century sink arc, and the ocean-box build

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, trunk `main`, clean at `cc87115`.
**Read with:** `handoff_2026-08-23b_figures_and_artificial_sink.md` (figures, plateau literature,
the 12.7 σ → 5 σ correction) and `handoff_2026-08-23_sweep_refit_and_rep_dC.md` (the sweep, the
refit, the Hessian). **This one is self-contained on the sink arc and specifies the next build.**

---

## 0. STATE IN EIGHT LINES

1. **THE NEXT STEP IS THE OCEAN-BOX FLUX.** Concrete spec in §4. It is the only way to test the
   hypothesis the isotopes actually favour, and every piece it needs already exists.
2. **¹⁴C REJECTS the reduced-fossil-emissions hypothesis** — the session's real result. §3.
3. **Marcus's concern has support**: pinning `luc_scale` moves `rep_dC` 5.57 → 4.10. §2.
4. **But the model routes around every prescribed perturbation** — twice now, via two different
   degenerate directions. §2. This is the methodological finding.
5. **No objective change.** Both switches default OFF; the shipped mode is untouched.
6. Two scratch dirs: `pump_arms_SINK25/`, `pump_arms_SINK25_PINLUC/`. **Never ship either.**
7. **Two of my own claims were withdrawn on measurement** — §5. Both are recorded because both
   would otherwise have been quoted.
8. Still no posterior.

---

## 1. THE QUESTION

Marcus: *"an artificial short-term ocean sink ... I think our fit to the modern period should be
best, and I am concerned that the model fit is being tweaked to match the 1935-1960 window when we
know that models don't explain that period well."* And then: *"the other possibility would be to
reduce emissions during that period, rather than changing the ocean sink — whichever helps the
model achieve the best fit. And the reductions (or additional absorption) would need to be
apportioned appropriately in order to get the right isotopic balance."*

**That is exactly the right frame, and the isotopes turn out to answer it.** The two hypotheses —
an ocean sink, or an emissions reduction — produce the *same* CO₂ trajectory and **differ only
isotopically**. So δ¹³C and Δ¹⁴C are the discriminator, which is also how the literature
attributes the plateau (`notes/lit_2026-08-23_1940s_co2_plateau.md`).

---

## 2. WHAT THREE RUNS SHOWED

Switch: `CCX_ARTIFICIAL_SINK_{WIN,RATE}` in `R/forcing.R` (via `CCX_SINK_RATE`), window 1942–49,
prescribed and **unfitted** — so it is *not* the §12c LUC programme the panel withdrew, which
fitted a free shape and would have reported a mechanism.

| | sink OFF | sink 2.5, `luc` free | sink 2.5, `luc` **pinned** |
|---|---|---|---|
| **`rep_dC`** | 5.566 | 5.126 | **4.102** |
| `luc_scale` | 0.8984 | **1.0852** | 0.8984 (pinned) |
| **`beta_max`** | 1.011 | 0.932 | **2.704** |
| **`fert_k`** | 554.5 | 422.6 | **1738.0** |
| `sigma_d14c` | 6.13 | 8.96 | 10.16 |
| **likelihood** | **−1789.9** | −1828.1 | −1860.6 |
| — CO₂ | −838.5 | **−822.6** | −853.6 |
| — isotopes | −836.7 | −884.5 | −890.9 |

*(Logposts −1859.32 / −1894.26 / −1920.92; the PINNED one is not comparable — its `luc_scale`
prior was replaced. Compare the likelihood.)*

**THE HYPOTHESIS HAS SUPPORT.** `rep_dC` falls monotonically as the mid-century is explained and
the escape routes are closed: **5.566 → 5.126 → 4.102**. A frozen 1-D scan (everything else fixed)
said 2.21, so the direction is right and the magnitude is being eaten by something.

**AND THE MODEL ROUTES AROUND EVERY PRESCRIBED PERTURBATION. Twice, by two different routes:**
- run 2: **`luc_scale` 0.898 → 1.085**, crossing 1.0, putting **54 GtC** of land-use emissions
  back against the sink's 20 GtC removal.
- run 3, with that pinned: **`beta_max` 0.93 → 2.70 with `fert_k` 423 → 1738** — the
  Michaelis-Menten pair recorded at **ρ = +0.997** (`ccx_seas_q10_ridge`).

> **THE METHODOLOGICAL FINDING, and it generalises past this model:** before running a
> prescribed-perturbation experiment, **enumerate every free direction that can undo it globally**,
> not just the obvious one. A near-degenerate pair is an escape route even when neither member
> looks related to the perturbation.

**Whether to pin `beta_max`/`fert_k` too is Marcus's call** — at some point pinning levers to force
an answer stops testing the model and starts constraining it into one.

---

## 3. THE REAL RESULT: ¹⁴C REJECTS THE EMISSIONS HYPOTHESIS

Pre-bomb Δ¹⁴C residual (model − obs, ‰):

| era | hemi | sink OFF | sink PINNED |
|---|---|---|---|
| 1941–1950 | NH | +3.23 | **+12.64** |
| 1941–1950 | SH | +0.82 | **+7.84** |
| 1950–1956 | NH | +0.64 | **+13.52** |
| 1950–1956 | SH | +5.36 | **+17.33** |

**Fossil carbon is ¹⁴C-FREE.** Emitting 20 GtC less of it in 1942–49 removes ~10 ‰ of Suess
dilution, the model's Δ¹⁴C rises accordingly, **and the pre-bomb record does not show it** —
`d14c_NH` −26.4, `d14c_SH` −25.9 (~52 log-units), with `sigma_d14c` inflating to 10.16 trying to
absorb it.

**⇒ THE ISOTOPIC APPORTIONMENT DISCRIMINATES, WHICH IS WHAT MARCUS ASKED FOR.**

| hypothesis | δ¹³C of removed C | ¹⁴C signature | status |
|---|---|---|---|
| fossil emissions overstated | −28 ‰ | large: removes ¹⁴C-free C ⇒ Δ¹⁴C **rises** | **REJECTED, ~52 logL** |
| LUC emissions overstated | ~−25 ‰ | intermediate (depleted, not ¹⁴C-free) | **untested — 3rd arm** |
| **ocean sink** | ~atmospheric, small ε | **~none** — removes C at the atmosphere's own ¹⁴C/C | **FAVOURED, untested** |

This independently reaches where the literature's δ¹³C double-deconvolution already sits (oceans
≥ two-thirds of the uptake; Rubino et al. 2019). **Two different isotopes, two different methods,
same answer.**

---

## 4. THE NEXT STEP: ROUTE THE FLUX INTO THE OCEAN BOX

**Why it is now the priority rather than cleanup:** §3 says ¹⁴C is what separates the hypotheses,
and the ocean version is the one ¹⁴C favours — but it **cannot be tested at all** with the current
switch, which is a *negative emission*, not an ocean uptake. The instrument to test the surviving
hypothesis does not exist yet.

**Everything it needs already exists, and the pump is the exact precedent.**

**4a. THE MECHANISM.** `R/model.R`'s `add_flux(from, to, F_C, alpha13, lab)` (line ~821) is the
isotope-safe, conservative mover: it takes isotope ratios from the **source** box, applies
`alpha13` to ¹³C, carries ¹⁴C **unfractionated** (Stuiver-Polach — Δ¹⁴C observations are already
fractionation-corrected, DESIGN §3.5), and records into the flux trace. **The pump was added
exactly this way**, and its comment says why: *"EMITTED THROUGH add_flux, NOT by touching dy: that
makes the pump conservative by the same construction as every other flux here."*

**4b. THE CALL.** Atmosphere → mixed layer, windowed in time:

```r
add_flux(iatm, iml, sink_rate_h, alpha13 = aux$alpha_as_down, lab = "artificial_sink")
```

- **`alpha13 = aux$alpha_as_down`** — the model's OWN air-sea downward fractionation, already used
  by the invasion flux at `R/model.R:1084`. **Do not invent a value**; reusing it is what makes
  this an ocean uptake rather than a number someone chose.
- **¹⁴C needs no argument** — `add_flux` carries it at the source ratio, which is precisely why
  this hypothesis produces no Suess signature and the emissions one does.
- **Hemispheric split**: apportion by the same shares the air-sea exchange uses (`aux$asx`), not
  by the fossil share.

**4c. IT MUST GO IN BOTH CORES.** `ccx_run_fast()` calls the C++ core (`src/ccx_core.cpp`, the
air-sea block at ~line 387). R-only would leave the sampler and every diagnostic on the un-sunk
model while the R path said otherwise. **`tests/testthat/test-parity.R` is the gate** — mirror the
block, then require bit-parity. Memory `ccx_pump_ported` records the pump doing this and having
all 7 tests re-derived.

**4d. GATES TO WRITE BEFORE BELIEVING IT** (the project's own discipline):
1. **Rate 0 reproduces bit-identically** — as `CCX_ARTIFICIAL_SINK_RATE` already does.
2. **Conservation**: total C, ¹³C, ¹⁴C closed to ~1e-10 with the flux on (DESIGN §6 gate 1).
3. **The ocean gains what the atmosphere loses**, to the same tolerance — the property the
   negative-emission version could not have.
4. **R/C++ parity** with the flux on.
5. **The ¹⁴C null**: at matched CO₂ removal, the ocean version must produce a **much smaller**
   Δ¹⁴C excursion than the −28 ‰ version. That is the discriminating prediction of §3 and it
   should be *pre-registered* — write it down before running.

**4e. THEN THE THREE-ARM COMPARISON.** Same CO₂ removal, three signatures: fossil (−28 ‰, done,
rejected), LUC (~−25 ‰), ocean (air-sea ε). **Same CO₂ trajectory by construction, so any logL
difference is purely isotopic** — which is the cleanest form of Marcus's apportionment question.
Run each with `luc_scale` pinned, and report `rep_dC`, the Δ¹⁴C residual by era, and the CO₂
streams.

---

## 5. TWO CLAIMS OF MINE WITHDRAWN ON MEASUREMENT

Both would have been quoted; both are in the code comments now.

1. **"The switch breaks conservation and contaminates δ¹³C."** **Wrong.** The cumulative budget gap
   is **identical** with and without the sink (**+260.95 GtC**) and emitted differs by exactly
   **20.00 GtC** — the carbon is simply never emitted, so nothing is lost; it carries `d13c_foss`
   and the correct ¹⁴C dilution. **It is a valid test of a real hypothesis**, not a broken ocean
   sink. *Check whether an implementation is wrong or merely different before calling its output
   contaminated.*
2. **"The mid-century window is where the fit is being damaged, so down-weighting it will help."**
   Answered the wrong question: I used **residuals** (the outcome of a fit) to argue **leverage**.
   The plateau window fits *well* precisely because the parameters may have been bent to it. Only a
   re-optimisation answers a leverage question. The per-era table in `LIK_ICE_DISCREPANCY`'s
   comment is correct about **offsets and σ** and **must not be read as answering the sink
   question.**

---

## 6. NON-OBVIOUS STATE

- **`CCX_PIN_LUC_SCALE`** collapses that prior to a near-delta (sd 1e-4). Gated: round-trips
  exactly; a 1 % move costs ~5000 log-units. **Laplace evidence from a pinned run is NOT comparable
  to an unpinned one.**
- **The pin block must sit AFTER the `h_ml` override's GATE H1**, which snapshots the whole
  parameter table and asserts only `h_ml` moved. Placing it earlier killed a run — correctly.
- Two switches, both OFF by default and both verified inert: `LIK_ICE_DISCREPANCY_*`
  (`co2_icecore` reproduces −690.86) and `CCX_ARTIFICIAL_SINK_*`.
- `sd_unc` is the posterior sd in the **unconstrained** coordinate; `par_mode` is **natural**
  scale. Dividing one by the other produced a nonsense "+2202 sd".
- Everything in handoff 2026-08-23 §7 and 2026-08-23b §5 still applies.

---

## 7. OPENING THE NEXT SESSION

```bash
cd ~/Documents/2026/CodeProjects/CarbonCycleEmulator && claude --remote-control ccx-dev
```

> Read `notes/handoff_2026-08-23c_ocean_box_next.md`.
>
> **BUILD §4: route the artificial mid-century flux into the OCEAN BOX** via `add_flux(iatm, iml,
> …, alpha13 = aux$alpha_as_down)`, mirrored in `src/ccx_core.cpp`, gated by `test-parity.R`,
> conservation, and the **pre-registered ¹⁴C null** in §4d.5.
>
> **Why:** ¹⁴C rejected the reduced-fossil-emissions hypothesis at ~52 log-units (§3), and the
> ocean version — the one both ¹⁴C and the published δ¹³C deconvolution favour — **cannot be
> tested with the current switch at all.**
>
> **Then §4e:** the three-arm isotopic comparison (fossil −28 ‰ done, LUC −25 ‰, ocean air-sea ε)
> at matched CO₂ removal with `luc_scale` pinned.
>
> **Open for Marcus:** whether to pin `beta_max`/`fert_k` as well. The model has routed around two
> prescribed perturbations already; pinning a third lever may cross from testing the model into
> constraining it to an answer.
>
> **Do NOT** ship either `pump_arms_SINK25*` directory, quote 12.7 σ (it is ~5), re-centre
> `rep_dC`'s prior, or point the ice-discrepancy window at the plateau.
