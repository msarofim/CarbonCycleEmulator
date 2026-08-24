# Handoff — CarbonCycleEmulator, 2026-08-24: the ocean-box arm, and what it closed

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, trunk `main`, clean at `c097ec7`.
**Read with:** `handoff_2026-08-23c_ocean_box_next.md` (the spec this discharges) and
`prereg_2026-08-24_ocean_sink_14c_null.md` (the predictions, written before any arm ran).

---

## 0. STATE IN SEVEN LINES

1. **§4 IS BUILT AND GATED; §4e IS RUN.** Both commits are on `main`.
2. **¹⁴C CLEARS THE OCEAN ROUTING BY 58–80×** — the pre-registered null holds. §2.
3. **AND THE CARBON BUDGET KILLS IT.** A mixed-layer sink cannot hold carbon. §3.
4. **NO REFIT WAS NEEDED OR RUN**, and that is a result, not a shortcut. §4.
5. **The `foss` and `ocean` arms BRACKET every ocean routing** — the fourth arm is unnecessary. §5.
6. **TWO DECISIONS ARE OPEN FOR MARCUS**, one carried from 23c and one new. §6.
7. Still no posterior. Objective unchanged. Both switches still default OFF.

---

## 1. WHAT WAS BUILT

`CCX_SINK_MODE` ∈ {`foss`, `luc`, `ocean`} selects the **isotopic signature at a fixed
magnitude** — one `sk` vector, three destinations, so the arms are magnitude-matched by
construction and a gate asserts it (all three remove 20.0000 GtC).

- **`ocean`** is `add_flux(iatm, iml, …, alpha13 = aux$alpha_as_down)`, ¹⁴C unfractionated at the
  source ratio, split on the **ocean-area** shares `aux$asx` — not the fossil share.
- It rides a new LAST forcing column `sink_ocean` and is **mirrored in `src/ccx_core.cpp`**
  (`N_FORCING` 14 → 15), so the sampler and every diagnostic see the same model the R path does.
- `ccx_build_forcing()` gained `sink_rate`/`sink_mode` **arguments**. The env constants are the
  defaults, so an env-driven refit is unchanged — but a diagnostic can now build all three arms in
  one process instead of re-sourcing `R/forcing.R` and silently testing the OFF state.

**Four mechanical gates**, `tests/testthat/test-artificial-sink.R`, 1007 pass against 977.
The two `test-fluxes.R:99/100` failures are the **pre-existing by-design ones** — verified against
a clean `git stash` before and after.

> **ONE GATE HAD TO BE REWRITTEN, and the correction generalises.** Asserting closed-system ¹⁴C
> conservation failed at **4.2e-4 — which is λ, not a leak.** ¹⁴C decays, which is why
> `test-conservation.R` gates C and ¹³C only. What must be conservative is the **sink's own
> contribution**: on-minus-off, which closes to 1e-12 in all three tracers and is strictly
> stronger than the total.

## 2. P1/P2 — THE ISOTOPES CLEAR IT

Pre-bomb Δ¹⁴C excursion against sink-off, per era × hemisphere:

| | `foss` | `luc` | `ocean` |
|---|---|---|---|
| 1941–50 NH | **+9.72** | +0.17 | **−0.12** |
| 1941–50 SH | +7.12 | +0.17 | −0.12 |
| 1950–56 NH | **+11.57** | +0.46 | **−0.16** |
| 1950–56 SH | +11.04 | +0.42 | −0.16 |

Worst-cell `|ocean|/|foss|` = **0.017** against a pre-registered ≤0.20, absolute **0.156 ‰**
against a pre-registered <1 ‰. δ¹³C the same, worst ratio **0.070**. On the likelihood at the
mode, `foss` pays **−46.8** on `d14c_NH` and −13.4 on `d14c_SH`; `ocean` pays **−0.20 / +0.47**.

**The 23c ¹⁴C rejection reproduces at the mode, un-refitted** — so it was never an artefact of
that refit's `sigma_d14c` inflation.

## 3. P3 — AND THE CARBON BUDGET KILLS IT

Atmospheric drawdown vs sink-off, ppm:

| epoch | `foss` | `luc` | `ocean` | ocean/foss |
|---|---|---|---|---|
| 1949.5 (window end) | −6.51 | −6.53 | **−1.76** | **0.271** |
| 1960.5 | −4.79 | −4.87 | −0.32 | 0.066 |
| 2024.5 | −2.81 | −3.27 | −0.05 | 0.017 |

Of **18.75 GtC** injected by the window end, the interior holds **3.02** and the mixed layer
1.38; by 1960 the interior holds 1.47, by 2024 **0.55**. Bisected on the model, matching the
`foss` arm's CO₂ effect needs **9.4 GtC/yr** at the window end, **42.7** at 1960 and **294** at
2024 — against a literature sizing of 2–3 GtC/yr and a present-day **total** global ocean sink of
~3 GtC/yr.

> **A SURFACE-OCEAN UPTAKE ANOMALY CANNOT HOLD CARBON OUT OF THE ATMOSPHERE.** What stays in the
> mixed layer is re-exposed on the ~1 yr air-sea time and comes back; only what the model's own
> transport ventilates below it stays down, and at the fitted transport that is ~16 % during the
> window and decaying.

**MY PRE-REGISTERED BAND WAS MISSED AT ONE EPOCH AND IS RECORDED AS MISSED.** I predicted
`ocean/foss` ∈ [0.08, 0.25] and measured **0.271** at the window end. The band came from the
*equilibrium* buffered-capacity partition (0.2503/(0.2503+2.1240) = 10.5 %) applied to an epoch
where the mixed layer has not yet given the carbon back and the sink is still running. Direction
right, endpoint wrong; the band holds at every later epoch.

## 4. WHY THERE WAS NO REFIT

At the adopted mode the arms cost **`foss` −796, `luc` −840, `ocean` −2.00** log-units.
**The ocean arm is free because it does almost nothing** — there is no misfit for a refit to
relieve, and three refits (~30 h) could not have made isotopically indistinguishable arms
distinguishable. The whole §4e comparison runs in **8 seconds**
(`calibration/diag_sink_three_arms.R`).

## 5. THE FOURTH ARM IS UNNECESSARY, AND THAT IS THE USEFUL PART

The obvious next move was an `ocean_deep` arm routing the flux below the mixed layer. **It is not
needed to know the answer.** A perfectly-ventilated ocean sink has:

- the **`foss` arm's CO₂ trajectory** — same removal, never returned; and
- the **`ocean` arm's isotopes** — removal happens at the atmosphere's own ratio *regardless of
  where the carbon ends up*.

So the two arms already run **bracket every ocean routing**, and the surviving hypothesis is not
"an ocean sink" but **"an ocean sink whose carbon is exported below the mixed layer as fast as it
is taken up"** — which is a statement about ocean *ventilation*, not about ocean *uptake*, and is
the thing the literature's SST/circulation explanations of the plateau actually assert.

## 6. OPEN FOR MARCUS

1. **Carried from 23c:** whether to pin `beta_max`/`fert_k` as well. The model routed around two
   prescribed perturbations; pinning a third lever may cross from testing the model into
   constraining it to an answer. **Note this is now much less pressing** — §4 says the ocean arm
   has nothing for a refit to route around.
2. **NEW:** whether to build the `ocean_deep` arm anyway. §5 says its CO₂ and isotopes are both
   already known, so it would buy only the *intermediate* cases — a finite ventilation rate rather
   than the two limits. **Its vertical profile is a mechanism choice and I have not made it.**
   The candidates are: the pump's own export shape (couples it to `pump_grad`), the top interior
   box only, or uniform over the interior.
3. **A different instrument may be the better one.** If the question is "could enhanced
   mid-century ventilation have held the carbon down?", the honest test perturbs `w_up` or the
   pump over the window — the model's own transport — rather than prescribing an artificial flux
   to an arbitrary depth.

## 7. NON-OBVIOUS STATE

- **`ccx_scaled_forcing()` and `ccx_make_logpost()` now ERROR on the `luc` arm** when
  `luc_scale != 1`. They apply `luc_scale` as a **column multiply**, exact only because the LUC
  columns are LINEAR in the annual series; the `luc` arm makes them **affine**, so the multiply
  would have rescaled the 2.5 GtC/yr perturbation to 2.5 × 0.8984. Build that arm with
  `ccx_build_forcing(luc_scale =, sink_mode = "luc")`. `foss` and `ocean` are unaffected.
- **`obs$d14$NH` DOES NOT EXIST.** `ccx_prepare_obs()` returns `d14_nh` / `d14_sh`
  (`t`, `d14c`, `sd_meas`, `sd`) and `d14_nh_ann` / `d14_sh_ann`. Indexing the wrong name printed
  NaN in every cell of a residual table on the first run.
- Two scratch dirs from 23c: `pump_arms_SINK25/`, `pump_arms_SINK25_PINLUC/`. **Never ship either.**
- New output: `calibration/output/sink_three_arms/three_arms_N_rate2.5.rds`.
- **Do NOT quote 12.7 σ** for the terrestrial rejection — it is ~5.1 (range 5–7); the root
  `MEMORY.md` line that still carried 12.7 was corrected on 2026-08-24.
- Everything in 23c §6 and 23b §5 still applies.

---

## 8. OPENING THE NEXT SESSION

```bash
cd ~/Documents/2026/CodeProjects/CarbonCycleEmulator && claude --remote-control ccx-dev
```

> Read `notes/handoff_2026-08-24_ocean_box_result.md`.
>
> The 1940s-plateau arc is **closed on the sink hypothesis**: ¹⁴C clears the ocean routing and the
> carbon budget kills it at any plausible magnitude. §6 carries the two open decisions.
>
> **Do NOT** re-run the three arms expecting a refit to change them (§4), build `ocean_deep`
> without settling its profile (§6.2), quote 12.7 σ, re-centre `rep_dC`'s prior, or ship either
> `pump_arms_SINK25*` directory.
