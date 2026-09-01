# Handoff — CarbonCycleEmulator, 2026-09-01
# **THE ENSO ARC: A RETRACTION THAT SURVIVED ITS OWN TEST.**
# **The model's OCEAN ENSO response is anti-correlated (r ≈ −0.50 over 66 yr);**
# **the conveyor is REFUTED as the fix; a FOUR-PARAMETER design is specified.**

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, trunk `main`, **clean at `cd6e652`**.
**Suite 1282 / 6 FAIL / 2 skip.** Nothing running. **Nothing adopted** — `CCX_MODE_CANONICAL` is
untouched and no parameter was added.

⚠ **SESSION CWD WAS `FaIRtoFrEDI/`; ALL THE CODE WORK IS IN `CarbonCycleEmulator/`.**

**Read `handoff_2026-08-31f_gates_repriced_and_torch_ready.md` FIRST** — its §8 and §9 carry the
`kz` re-bisection, the gate re-pricing and the Torch bundle, none of which is repeated here. **This
file is the ENSO arc only.**

---

## 0. STATE IN SIX LINES

1. ⛔ **The model's ocean sink is ANTI-correlated with ENSO** — r ≈ −0.50 over 1959–2024, p = 1e−4,
   CIs non-overlapping with the observed +0.535. **Powered, detrend-invariant, both basins.** §2
2. ⭐ **Structurally explained: there is no upwelling to suppress.** ENSO enters as a LAND-ONLY flux;
   the ocean feels it only through SST. §3
3. ⛔ **The conveyor is REFUTED as the fix** — wrong sign, implausible magnitude, worsens deep Δ¹⁴C.
   Killed in one minute by a static scan, before any plumbing was built. §4
4. ⭐ **The model sits in a COMPENSATING-ERROR state**: land 53 % too weak, ocean wrong-signed, the
   two cancelling **87 %** in atmospheric CO₂. **An ocean-only term would make things worse.** §5
5. ✅ **Marcus specified a FOUR-PARAMETER design** (land/ocean × NH/SH, each carrying its own path's
   fractionation) and **that isotope choice is what makes them identifiable.** NOT IMPLEMENTED. §6
6. ⚠ **I over-read a single event and was corrected. The retraction was right about the METHOD and
   the conclusion survived it.** The reasoning failure is the most transferable thing here. §1

---

## 1. HOW THIS STARTED, AND THE MISTAKE WORTH REMEMBERING

Marcus supplied **Ke et al. (2026), iScience 29(8):117053** (open access, 2026-08-21) as background
on low-latency carbon budgets. Our historical run ends inside the event it quantifies, so I tested
the mechanism — and reported the model's 2023/24 ocean response as a **sign contradiction**.

⛔ **Marcus: "Don't over-read a single year: every ENSO is going to have somewhat different impacts
on land and ocean carbon, our best will only ever capture the average response (modulated by
intensity)."** He was right, and the arithmetic I had not done says so: model − obs on that ocean
delta is **0.60 σ** of GCB's own stated two-year bar. **Not a detection.**

**Three errors, all mine, all worth carrying forward:**
- **No error bar before the claim.** And the bar is itself ambiguous — GCB's stated 0.40 is
  systematic and largely cancels in a difference, while the series' own year-to-year sd of **0.11**
  is a smoothed model-ensemble mean. The same delta is **0.6 σ against one and 2.4 sd against the
  other**, which is itself the proof one event cannot settle it.
- ⛔ **"Both basins agree, so it's structural" is NOT evidence** when both are fits of ONE structure
  sharing ONE `gamma_enso`. Two fits of one model are not two lines.
- ⛔ **I called it model-vs-observation and it is model-vs-MODEL.** GCB's ocean sink is a product
  ensemble; Ke et al.'s +0.38 comes from ML emulators of ocean biogeochemical models.

⇒ **STANDING RULE: a one-parameter ENSO response can only capture the AVERAGE response modulated by
intensity. Test it as a regression over ALL events, never on one.** [[ke2026_elnino_ocean_sign]]

## 2. THE TEST DONE RIGHT — AND THE CONCLUSION SURVIVED

**First, the power check** (`diag_enso_sink_power.R`, observations only, no model): can the series
show the effect at all? A null from a blind series is worthless.

| sink | best lag | r | 95 % CI | slope (GtC/yr per °C) | n → n_eff |
|---|---|---|---|---|---|
| **land** (positive control) | 3 mo | **−0.677** | [−0.790, −0.519] | **−0.665** | 65 → 65 |
| **ocean** | 2 mo | **+0.535** | [+0.287, +0.716] | **+0.119** | 65 → **45** |

✅ **The control passes**, so a null would have meant something. There isn't one. 13/13 lags
individually significant; stable across detrending orders; `n_eff` corrected because the detrended
ocean series has lag-1 autocorrelation **0.60**. ⛔ **It also retires a number: Ke et al.'s 0.38 is
4.5× the measured slope — an event anomaly, NOT a per-unit sensitivity. Use +0.119.**

**Then the model** (`diag_enso_model_vs_obs.R`, shared estimator):

| | land slope | ocean slope | ocean r (95 % CI) |
|---|---|---|---|
| **observed** | **−0.665** | **+0.119** | **+0.535** [+0.287, +0.716] |
| incumbent | −0.383 (**58 %**) | **−0.109** | **−0.496** [−0.673, −0.265] |
| new basin | −0.352 (**53 %**) | **−0.155** | **−0.506** [−0.680, −0.278] |

⭐ **The amplitude is RIGHT and the PHASE is wrong**: the incumbent's detrended ocean residual sd is
**0.122** against the observed **0.123**. The ocean is not too quiet; it moves the wrong way.

## 3. WHY — READ FROM THE CODE, NOT INFERRED

- **ENSO enters as a LAND-ONLY flux**: `R/model.R:1256`, `soil_fast → atm`, scaled by `gamma_enso`.
- **The ocean feels it through exactly ONE path, SST**: `cor(sst_anom_NH, Niño3.4) = +0.397`,
  `sst_anom_SH = +0.401`. Warmer ⇒ lower solubility ⇒ **weaker uptake**. The thermal term, alone.
- ⛔ **There is NO upwelling to suppress.** The conveyor IS built (`ccx_conveyor_geom()`, sinking
  limb, upwelling hemisphere, `conv_sink`/`conv_reverse`/`conv_descent`) but **`q_conv = 0`, it is
  NOT in `CCX_PARAM_TABLE`, and it is absent from the fitted mode** — inert since 2026-08-13.
  Vertical transport is **time-invariant diffusion**. The pump is live but constant-mass.
- ⇒ **No value of `gamma_enso` can fix this, because `gamma_enso` only moves land.**

## 4. THE CONVEYOR IS REFUTED — AND CHEAPLY

The obvious step was to make `q_conv` time-varying: new forcing column, R **and** C++ twins, parity
test, `N_FORCING` bump. ⭐ **A STATIC scan over `q_conv` asks the same question in one minute.**
**Measure the lever before building the machinery.**

- ⛔ **The sign is wrong.** `d(ocean sink)/dq = +0.0101 GtC/yr per Sv` — **more conveyor, MORE
  uptake**. El Niño *suppressing* the cell makes the response **more negative**. Closing the gap
  needs El Niño to *strengthen* it, the opposite of the physical story. In a transient anthropogenic
  run, ventilating deep water undersaturated in anthropogenic carbon beats upwelling DIC-rich water.
- ⛔ Magnitude implausible anyway: **136–542 % of the whole circulation per °C**.
- ⛔ Worsens the deep gate: Δ¹⁴C **−158.8 → −135.0** against GLODAP's −175.3.
- ⭐ **20 Sv moves the sink by only 0.20 GtC/yr — transport is a WEAK lever on this ocean**, a third
  instance of the standing reading that the defects are capacity, not transport.
- ✅ **By-product:** `test-conveyor.R` never sets `pump_grad`, `test-pump.R` never sets `q_conv` —
  **pump+conveyor had NO coverage.** Carbon closure holds to **1.8e−10 GtC over 274 yr**.
  **Worth promoting to a real test.**

## 5. ⭐ THE COMPENSATING-ERROR STATE — THE KEY RESULT

All in **GtC/yr per °C** (⚠ GCB `atm_growth` is **GtC/yr**, the model's growth is ppm/yr; comparing
them raw is a factor-2.124 error that **inverted this file's first answer**. Units settled by the
BUDGET IDENTITY, not by a magnitude heuristic — which got it wrong):

| | land | ocean | CO₂ growth |
|---|---|---|---|
| **observed** | −0.665 | **+0.119** | **+0.757** |
| model | −0.352 (53 %) | **−0.155** | +0.404 (53 %) |

**Land short by −0.314, ocean off by +0.274 — opposite effects on the atmosphere, cancelling 87 %.**
That is why growth is a respectable 53 % while both components are badly wrong, and **why the fit
never forced it: CO₂ outvotes partition 40:1**, so only the weak streams can see the error.

- ⛔ **Ocean-only would take growth 53 % → 17 % of observed.**
- ✅ **Ocean + land together**: `gamma_enso` × 1.89 with `gamma_enso_ocn` = +0.274 → both partitions
  right, growth **53 % → 72 %**.
- ⚠ **A CEILING FROM THE DATA:** GCB's own slopes do not close — −(land+ocean) = +0.547 against a
  measured growth of +0.757, the **+0.210 gap living in the imbalance term. No model tuned to those
  sink products can exceed ~72 %.** Know this before chasing the last 28 %.

## 6. ✅ THE DESIGN (Marcus, 2026-09-01) — SPECIFIED, NOT IMPLEMENTED

1. **Four ENSO parameters**: `gamma_enso_land_NH/_SH`, `gamma_enso_ocn_NH/_SH`. 22 → **25**.
2. **Each anomaly carries the fractionation of its own uptake path.**

⭐ **CHOICE 2 IS LOAD-BEARING — it is what makes them IDENTIFIABLE.** From the model's own state:
land `soil_fast → atm` is **−24.35 ‰** ⇒ **−0.0172 ‰ per GtC**; ocean invasion is **+0.0022 ‰ per
GtC** — **~8× weaker and opposite**. ⇒ **δ¹³C identifies the LAND terms; CO₂ identifies the OCEAN
terms by difference**; MLO vs SPO (separate high-leverage streams in both tracers, plus the two
gradients) separates the hemispheres. **With generic fractionation this identifiability disappears**
and the `gcb_*` streams alone could never have separated land from ocean.

⚠ Structural identifiability, **not demonstrated precision** — that needs a profile/Hessian after
implementation. ⚠ `enso_share` is a hardcoded `list(NH = 0.5, SH = 0.5)` (`R/model.R:1870`) that this
design **replaces**.

**Implementation needs:** R + C++ twins, a parity test, an `N_FORCING` bump if a forcing column is
added, and **a behaviour-preserving default** — the land term must reproduce exactly at
`gamma_enso_land_NH = gamma_enso_land_SH = gamma_enso/2` with the ocean terms 0. (The `gamma_diff`
adoption did NOT have one; it should have.)

## 7. FILES

**New this arc** — all adopt nothing:
`diag_elnino_2023_sink_response.R` (year-by-year sinks; **verdict retracted**, reports the bar),
`diag_enso_sink_power.R` (the power check), `diag_enso_model_vs_obs.R` (the regression),
`diag_conveyor_enso_lever.R` (the refutation), `diag_enso_ocean_term_design.R` (the pricing),
`lib_enso_regression.R` (shared estimator).
**Refactor:** `dg_annual_sinks()` extracted into `lib_design_gates.R`; gate 7 is now its window mean
and the El Niño diagnostic no longer carries a copy. **Gate 7 verified bit-identical**, as was the
power test across the regression extraction.

## 8. ⚠ NON-OBVIOUS STATE

- ⚠ **A top-level `if (...) expr` / newline / `else` does not parse in R.** I hit this in
  `run_dispersed_multistart.R`, wrote the warning into that file, **and then repeated it** in
  `diag_conveyor_enso_lever.R` the same day. Brace it.
- ⚠ **Start the forcing at 1750, not 1959.** A 1959 start leaves 165.8 GtC of land-use carbon already
  emitted against preindustrial spinup stocks and puts a start-up transient inside the measurement
  window. `ccx_build_forcing()` warns; heed it. Use `DG_YEARS`.
- ⚠ **`atm_growth` is GtC/yr.** Settle units from the budget identity, never a magnitude heuristic.
- ⚠ The GCB ocean sink is a **product ensemble**, not measured air-sea flux. An observational
  cross-check (pCO₂ products, atmospheric O₂/N₂) is the way to escape model-vs-model entirely.
- **Everything in `handoff_2026-08-31f` §8/§9 still stands**: the `kz` bracket is
  **[4379.1, 8109.9]**; `test-likelihood.R:578` fails deliberately; two `test-mode-decode.R`
  failures will **INVERT** on adoption; Torch is bundled and ready with **Marcus to submit**.

## 9. NEXT

1. **Implement the four-parameter ENSO design** (§6) — the only piece with a specification and no code.
2. **Promote the pump+conveyor carbon-closure check to a real test** (§4).
3. **Cross-check the +0.119 target against a genuine observation** — pCO₂ or O₂/N₂ — to escape
   model-vs-model.
4. Still open from 08-31f: adopt the polished mode (after the survey), and the Torch survey itself.
