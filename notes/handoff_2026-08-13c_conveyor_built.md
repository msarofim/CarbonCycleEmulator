# Handoff — CarbonCycleEmulator, 2026-08-13 (c)

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, branch `luc-veg-debit`
(= `d50e963` + the Part-4 commit, **still not merged**). Suite **462 pass / 4 fail /
2 skip** — the same four failures as 12d/13/13b, plus 36 new assertions.

Supersedes nothing. It **discharges** `handoff_2026-08-13b_ocean_advection_and_conveyor.md`
§§4 and 6: the oceanic-Suess lead was verified (and failed), the conveyor was red-teamed,
approved, built, and measured. 13b §5 (the σ decision) **is still open and still blocking**.
12d §§2–8 and §10 continue to apply.

---

## 0. START HERE

1. **`sigma_d13c` is STILL the blocker and `CCX_PARAM_TABLE` is STILL untouched.** Nothing
   in this session changed the 0.45 ‰ argument. Marcus asked "the new conveyor mechanism
   won't help?" — measured answer: at fixed `kz` it buys 0.065 ‰ of the 0.55 ‰ gap, so the
   residual would still be ~0.48 ‰. **Do not block σ on the conveyor.**
2. **Two NEW decisions are now blocking the refit** (§5). Both are Marcus'. The deep-Δ¹⁴C
   target must be re-chosen before any refit, because the model's deep ocean is now
   **bipolar** and `CCX_PARAM_TABLE`'s `[−150, −200]` is a global-average bracket derived
   on a single-column ocean.
3. **The conveyor is BUILT, TESTED, and OFF BY DEFAULT.** `q_conv = 0` bit-reproduces every
   pre-2026-08-13 result. Nothing samples it; it is not in `CCX_PARAM_TABLE`.
4. **Read §2 before trusting handoff 13b's §4 arithmetic** — three of its load-bearing
   claims were wrong, in both directions.

---

## 1. What this session settled

| | result |
|---|---|
| §2 | 13b §4.2's "`ccx_spinup()` needed no change at all" is **FALSE**, and silently so: −0.915 ‰ of spurious δ¹³C drift. Fixed. |
| §2 | 13b §4.3's transit arithmetic divides by a volume its own plumbing does not traverse. Two errors that nearly cancel. |
| §3 | The oceanic Suess effect is now **measured and scoreable**. The model's mixed layer is right; its atmosphere is 21–25 % too fast. |
| §4 | The conveyor **works**, gives a bipolar deep ocean, and passes the reverse-conveyor gate. But 13b §4.4's own falsification test **fails**. |
| §4 | The red team's ml-Suess objection was **wrong by 4×** — in the way the red team itself flagged. |
| §6 | The preindustrial CO₂ gradient the conveyor creates is **not testable from ice cores**; the preindustrial **Δ¹⁴C** offset is, and the conveyor improves it. |

---

## 2. THREE THINGS HANDOFF 13b §4 GOT WRONG

**Recorded prominently because two of them would have been invisible.**

### 2a. §4.2: "`ccx_spinup()` needed no change at all" — FALSE

The claim was that every box gains Q and loses Q, so a uniform-concentration ocean is still
an exact fixed point. **True within a column, false between them.** The two columns sit at
**different DIC** — SST 18 vs 16 °C gives 2.03786 vs 2.05570 mol/m³, 0.87 % apart — so the
interhemispheric limbs, the first ocean–ocean coupling in the model, see a real gradient
and converge **0.135 GtC/yr** into the NH at 20 Sv.

**Measured cost of believing it:** spinup residual 6.3e-09 → **1.35e-01**, and over a
zero-emission 1750–2024 run the atmospheric δ¹³C **drifts −0.915 ‰** against −0.036 with
the conveyor off. That artefact is **nearly twice the entire δ¹³C misfit the conveyor was
proposed to fix.** It would have looked like a result.

**Diagnosed, not guessed:** setting `sst_NH = sst_SH = 17` returns both the residual
(5.15e-09) and the drift (−0.0362) to their conveyor-off values exactly.

**The first fix was also wrong,** and is worth knowing about. An ocean-only solve with both
atmospheres pinned at 278 ppm left exactly **0.1226 GtC/yr in the two atmosphere boxes,
equal and opposite**. That is not an error to squash: the conveyor makes one hemisphere's
mixed layer outgas and the other ingas, so the preindustrial atmosphere **must** carry a
small interhemispheric gradient for `tau_ex` to move the difference back. Pinning both
hemispheres forbade the very thing that had to move.

`ccx_c12_steady_conveyor()` (in `R/spinup.R`) is therefore a Newton on the **full state**,
using `ccx_deriv()` **itself** as the residual so the solve cannot disagree with the model
it is solving. Global preindustrial CO₂ is the pin; the split is free. Residual 1e-13,
drift 0, R/C++ parity exact.

**Physical consequence, and it corrects my own red team:** between columns the conveyor is
**not** the pure isotope operator it is within one. It carries carbon from the colder,
DIC-richer hemisphere to the warmer one — **a crude solubility pump the model did not
have.**

### 2b. §4.3: the transit arithmetic divides by the wrong volume

§4.3 uses `V_deep` = the whole sub-mixed-layer ocean (1.309e18 m³). Under §4.2's own four
limbs the path is NH bottom → SH bottom → up the SH column → SH ml → NH ml =
**9.13e17 m³, 70 %**. **NH `oc1`–`oc9`, 30 % of the deep ocean, gets no advective flux.**

| basis | Sv for deep Δ¹⁴C = −170 ‰ |
|---|---|
| `V_deep`, no source correction (§4.3's headline) | 27.1 |
| `V_deep`, source −51.2 ‰ (§4.3's own hedge) | 37.7 |
| `V_path`, no source correction | 18.9 |
| **`V_path`, source −51.2 ‰ — honest** | **26.3** |

The two errors nearly cancel, so the headline survives — **but §4.3's hedge ("~37 Sv") is
too pessimistic by 11 Sv.** Separately: **27 Sv is far above the AMOC that has an error
bar** (RAPID 26°N, **16.9 ± 1.2 Sv**, 2004–2020). **Retire "27 Sv reproduces −170 ‰ from
transit alone."** The claim that survives is a joint (Q, `kz`) result.

### 2c. §4.4's falsifiable prediction — FAILS

§4.4: *"it should shrink the model's NH−SH δ¹³C gradient... if the gradient does not
shrink, the mechanism is not doing what this section says."*

**It does not shrink.** MLO−SPO goes **−0.218 (off) → −0.221 (20 Sv) → −0.223 (27 Sv)** —
very slightly the *wrong* way, against an observed −0.074. Falling `kz` recovers only
−0.215 at kz 2000. **On its own stated test, the §4.4 mechanism does not do what §4.4
says.** §6 below offers a replacement test that the conveyor does pass.

---

## 3. The oceanic Suess effect — now a real, citable constraint

`calibration/diag_oceanic_suess.R`, data in `data/obs_oceanic_suess.rds`, sources in
`DATA.md` §2b.

- **Quay et al. 2003** (GBC 17(1):1004): global mean surface DIC δ¹³C fell
  **0.16 ± 0.02 ‰/decade**, 1970s vs 1990s. **Has an error bar; the candidate likelihood term.**
- **Eide et al. 2017** (GBC 31:492–514; PANGAEA 871993, CC-BY — **paper paywalled, gridded
  field is not**): **0.916 ‰ at 0 m, 0.782 ‰ over 0–75 m**, area-weighted by us.

**13b §6's recollected ratio (0.35–0.45) was wrong in value and sign.** Measured, observed
is 0.56–0.71 and the model's is 0.53–0.55. **The ocean half of the recollection was fine
(0.6–0.9 ‰); the error was the ATMOSPHERIC DENOMINATOR — recalled ~1.9 ‰ against Law
Dome's actual 1.386 ‰.** A 37 %-inflated denominator alone manufactured the conclusion.

**Split into limbs:** mixed layer **0.156 vs 0.160 ± 0.020 (−0.2 σ, window-insensitive)**;
atmosphere **+25 % too fast**, reproduced against Scripps flask as well as Law Dome.
**The model's ocean takes up ¹³C at the observed rate.**

**Caveat that cuts both ways:** an atmosphere 25 % too fast driving a ml exactly on
observation implies air–sea ¹³C transfer ~20 % too weak — *but* τ_eq = C_ml/F_gross =
10.5 yr (NH) / 10.0 (SH) is the textbook value, so if τ_eq is right the 20 % lives
elsewhere, most likely `h_ml`. **Open. The refit separates them.**

**Eide caveat, verified at build and re-asserted on every rebuild:** above 200 m the field
is the 200 m back-calculation plus a **spatially constant** depth offset (level-diff sd
exactly 0). **Global mean usable; NH/SH contrast above 200 m must not score a hemispheric
gradient.**

---

## 4. The conveyor as built

`R/model.R` (params + `ccx_conveyor_geom()` + limbs), `src/ccx_core.cpp` (mirror),
`R/spinup.R` (the ¹²C solve), `tests/testthat/test-conveyor.R` (8 tests),
`calibration/diag_conveyor.R` (~1 min, carries its results in its header).

| parameter | meaning |
|---|---|
| `q_conv` | Sv. **0 = off and nothing is emitted** |
| `conv_sink` | interior layer the sinking limb feeds (**structural**) |
| `conv_descent` | 0 = non-local plume, 1 = distributed (**structural**) |
| `conv_reverse` | 1 = run the cell backwards. **Wiring gate only, never physical** |

**Configs:** A = sink 10 / non-local (§4.2 as written); B = sink 10 / distributed;
**C = sink 8 / non-local (NADW depth) — the DEFAULT**, per the red team, because A leaves
NH `oc1`–`oc9` advectively dead and plumbs a limb named "NADW" to AABW depth.

**The reverse-conveyor gate PASSES.** Reversed, the atmosphere differs (0.15 ppm CO₂,
1.8 ‰ Δ¹⁴C) and the deep ages **swap**: forward NH −113 / SH −157, reversed NH −159 /
SH −120; off, they are equal (−170.8 / −169.5).
**GOTCHA, and my first version of the gate fell into it:** it must be read off an
**INTEGRATED run**. The conveyor touches no atmospheric box directly, so `dy[atm]` is
identical forward and reversed at any fixed state — a derivative-level assertion is a gate
that can never fail.

### What it does, at default parameters

| | deep NH | deep SH | ml Suess | δ¹³C bias | MLO−SPO | CO₂ bias |
|---|---|---|---|---|---|---|
| OFF, kz 5000 | −170.8 | −169.5 | 0.156 (−0.2σ) | +0.548 | −0.218 | +2.3 |
| C 20 Sv, kz 5000 | −112.9 | −157.2 | 0.147 (−0.6σ) | **+0.500** | −0.221 | +5.4 |
| C 27 Sv, kz 5000 | −106.8 | −148.3 | 0.144 (−0.8σ) | **+0.483** | −0.223 | +6.5 |
| C 20 Sv, kz 2000 | −158.6 | −222.5 | 0.185 (+1.2σ) | +0.678 | −0.215 | −5.8 |
| C 20 Sv, kz 1000 | −214.3 | −277.1 | 0.212 (+2.6σ) | +0.820 | −0.211 | −12.5 |

**The red team's ml-Suess objection was wrong by 4×, in the way the red team flagged.** It
estimated −3.2 σ while stating that was an upper bound because a falling `kz` pushes back.
Measured: **−0.6 σ at fixed `kz`**, and as `kz` falls the rate reverses and **overshoots
Quay from above**. **`kz` is now squeezed from both sides** — deep age wants it small, ml
Suess wants it large — which is far better than the predicted degenerate ridge.

**The structural win: the deep ocean goes bipolar**, in the observed sense (young ventilated
end, old far end). **The cost: `kz` cannot actually fall far** — which was the strongest
argument for building at all (5000 m²/yr is ~9× Ledwell's NATRE thermocline value of
(1.7 ± 0.2)×10⁻⁵ m²/s = 536 m²/yr). δ¹³C and CO₂ both degrade sharply as it drops.

**None of this is a verdict.** Every parameter except `q_conv` and `kz` is frozen at its
default. **The refit is the experiment.**

---

## 5. THE TWO DECISIONS BLOCKING THE REFIT — Marcus'

1. **The deep-Δ¹⁴C target.** `CCX_PARAM_TABLE`'s `[−150, −200]` is a **global-average**
   bracket bisected on a **single-column** ocean (12d §6). The model's deep ocean is now
   bipolar, and NH −159 / SH −223 at kz 2000 is plausibly a *better* representation of a
   real ocean (young deep North Atlantic, old deep North Pacific) than the flat −170 it
   replaces. **But which target replaces it must be chosen BEFORE the refit, not after
   seeing that table.** 12d §0 step 2 already calls for a deep-Δ¹⁴C likelihood term; it is
   now a prerequisite, not a nice-to-have.
2. **Whether to promote Quay's ml Suess rate to a likelihood term.** It is the only new
   constraint with a stated uncertainty, it is independent of the atmospheric δ¹³C target,
   and it now binds `kz` from above.

**Plus the standing one: `sigma_d13c`.**

### The refit design, once those are settled

- **Delete `kz`'s `[3830, 6200]` bracket** — do not carry it across (12d §6: conditional on
  the pure-diffusion column). Honest accounting: **one parameter added, one constraint removed.**
- **Four refits:** baseline off; A; B; C. Same likelihood, same terms. **~4 h each.**
- **Compare parameter VECTORS, not just log-posterior.** A better fit bought by driving
  `k_w` or `h_ml` somewhere indefensible is not a better model.

**The scorecard, stated in advance so it cannot be retrofitted:**

| parameter | now | prediction | status after this session |
|---|---|---|---|
| `kz` | 6031 | falls toward 500–2000 | **in doubt** — δ¹³C and CO₂ both degrade as it falls |
| `h_ml` | 179 m (88 % up its bound) | falls | untested |
| `tau_ex` | 0.856 | rises | untested |
| MLO−SPO δ¹³C | −0.218 vs −0.074 | shrinks | **FAILED** (§2c) |

---

## 6. The preindustrial gradient — Marcus asked, 2026-08-13

The conveyor gives the preindustrial atmosphere a gradient it did not have (§2a). Is it
observable?

| config | CO₂ ppm | δ¹³C ‰ | Δ¹⁴C ‰ |
|---|---|---|---|
| OFF | +0.0000 | +0.00000 | +0.997 |
| C 20 Sv | **+0.1492** | +0.00159 | **+2.400** |
| C 27 Sv | +0.1947 | +0.00156 | +2.371 |

### CO₂ from Greenland vs Antarctic ice: **NO, and not marginally**

Greenland ice CO₂ runs **20–30 ppm ABOVE** the Antarctic composite, with a standard
deviation of **6–10 ppm** against 2–3 ppm in Antarctic ice. The cause is **in-situ
production** — carbonate–acid reactions and oxidation of organics, on Greenland's much
higher carbonate load (~0.4 ± 0.2 µmol/L vs far lower in Antarctic ice). Anklin et al.
1995; Barnola et al. 1995; Tschumi & Stauffer 2000.

**The artefact is ~150× the model's predicted signal and the scatter alone is ~50×.** This
is not "weak evidence"; the measurement cannot see 0.15 ppm even in principle. **Antarctic
cores are the reliable CO₂ record precisely because Greenland's are not**, so there is no
ice-core CO₂ pair that constrains this.

**One unverified lead, flagged not adopted:** a search result attributed to a CanESM1
preindustrial control run states the preindustrial interhemispheric CO₂ gradient was
**reversed** from today's (SH higher). If true our +0.149 ppm has the wrong **sign**. It
came from a model paper via a search snippet, **not from observations, and I have not read
it.** Worth checking before the sign is ever quoted.

### Δ¹⁴C: **YES, and this is the apposite test**

**SHCal20 puts the Southern Hemisphere 36 ± 27 ¹⁴C yr OLDER than the North.** Converting on
the Libby mean life (8033 yr, the convention ¹⁴C *ages* use): **NH−SH Δ¹⁴C = +4.49 ± 3.38 ‰.**

| | Δ¹⁴C ‰ | % of SHCal central | z |
|---|---|---|---|
| conveyor OFF | +1.00 | 22 % | −1.04 |
| C 20 Sv | **+2.40** | **53 %** | **−0.62** |

**The conveyor moves it the right way and closes about half the gap.** This matters more
than the arithmetic suggests: the observed interhemispheric ¹⁴C offset is driven
substantially by **Southern Ocean upwelling of ¹⁴C-depleted water** — *exactly* the limb
the conveyor adds (cf. Rodgers et al., "Interhemispheric gradient of atmospheric radiocarbon
reveals natural variability of Southern Ocean winds").

**Honest limits:** ±27 ¹⁴C yr is too wide to discriminate strongly — OFF is also inside 1 σ.
And the model's +1.00 ‰ with the conveyor off is not zero, so part of the offset is already
being produced by hemispheric area/ventilation asymmetry rather than by the new mechanism.
**But this is the independent, already-observed test that §4.4 wanted and did not get, and
it is the one to score the conveyor on.** Adding it as a likelihood term is a third
candidate decision for Marcus.

---

## 7. Non-obvious state

- **Four new parameters, all inert by default:** `q_conv` (0), `conv_sink` (8L),
  `conv_descent` (0L), `conv_reverse` (0L). In `ccx_default_params()` and in
  `ccx_cpp_par()`'s selection vector. **NOT in `CCX_PARAM_TABLE`** — the count is still 16.
  The three structural ones are coerced to **integer** in `ccx_cpp_par()` because
  `unpack_par` reads them into `int`.
- **`aux$a_oc` is new** and marshalled to C++. The conveyor's interhemispheric limbs are
  the only fluxes in the model where the hemisphere's area does **not** cancel between
  source and sink.
- **`ccx_advection_eigbound()` gained a `p` argument** and now folds in the conveyor
  (`Q / A_min`). At physical values it does not change the substep count — diffusion still
  dominates — but a stability check that ignored a 20.8 GtC/yr advective term would be
  worse than none.
- **`ccx_spinup()$diagnostics$d14c_deep_by_hemi` is new.** The combined
  `d14c_deep_ocean` is kept because every pre-conveyor result and the `kz` bracket came
  from it, but it is **meaningless under a conveyor** — read the split.
- **`ccx_deriv()` needs `gamma_enso` set explicitly.** It is not in
  `ccx_default_params()` (only `ccx_cpp_par()` defaults it), so a hand-built diagnostic
  that omits it dies with "argument is of length zero" inside `add_flux`. Cost me a
  debugging cycle; the existing tests all set it.
- The four suite failures are **unchanged and pre-existing** (`test-climate.R:122` γ_L
  structural; `test-likelihood.R:114/117` stale fixture; `test-mechanisms.R:32`
  `gamma_enso` pinned by the test). None relates to this work.
- Everything in 12d §10 still applies — `kz` default **5000**, freezing a parameter is a
  `CCX_PARAM_TABLE` deletion, `beta` and `kz` are `logit` not `log`, `run_modefind.R` costs
  ~4 h per refit.

## 8. Commits

| | |
|---|---|
| `62b0413` | The oceanic Suess effect, measured: the mixed layer is right, the atmosphere is not |
| `7db1a5a` | `diag_oceanic_suess`: state where the conveyor pre-check is weak |
| `6389bb8` | Red team on the conveyor configurations: §4.3 divided by the wrong volume |
| `b07d615` | The conveyor, built: Configs A/B/C, and §4.2's spinup claim was wrong |
| `d50e963` | `diag_conveyor`: measured against every gate; §4.4's own prediction fails |

## 9. Opening the next session

```bash
cd ~/Documents/2026/CodeProjects/CarbonCycleEmulator && claude --remote-control ccx-dev
```

> Read `notes/handoff_2026-08-13c_conveyor_built.md`, then
> `notes/redteam_2026-08-13_conveyor_configurations.md` for the configuration
> analysis and `notes/handoff_2026-08-12d_frozen_land_bounded_kz.md` for §§2–8 and §10,
> on branch `luc-veg-debit`. Three decisions are open and all are Marcus': `sigma_d13c`
> (still blocking, do NOT block it on the conveyor), the deep-Δ¹⁴C target for a now-bipolar
> ocean, and whether Quay's ml Suess rate and the SHCal interhemispheric ¹⁴C offset become
> likelihood terms. **Do not start a refit until the deep-Δ¹⁴C target is chosen** — the old
> `[−150, −200]` bracket is a global average from a single-column ocean and must not be
> carried across.
