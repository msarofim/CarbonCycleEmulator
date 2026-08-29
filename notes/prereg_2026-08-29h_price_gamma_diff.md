# PREREG 2026-08-29h — **PRICE `gamma_diff` CONDITIONALLY**
# Marcus, 2026-08-29: *"Price gamma_diff conditionally first."* Written BEFORE the driver.
# **No gate below may move.**

**State:** `main` at `827fb88`, clean, suite **1222 / 2 skip / 0 fail**.

## 0. WHY

08-29g landed diffuse-light fertilisation and measured, **FROZEN at the mode's other parameters**:

| `gamma_diff` | 1992 | sd | r | Δlogpost frozen |
|---|---|---|---|---|
| 0 | +0.043 | 0.301 | 0.571 | 0 |
| 0.25 | −0.466 | 0.320 | **0.625** | **−40.5** |
| 0.50 | −0.975 | 0.365 | **0.625** | −160.8 |
| 0.97 | −1.934 | 0.491 | 0.573 | −601.3 |

**A frozen cost is an UPPER BOUND, not a price** — "the refit recovered 15-19× more than the frozen
scan predicted" (handoff 08-25b §7). **This run asks what it actually costs.**

## 1. THE DESIGN

Grid `gamma_diff` ∈ {0, 0.125, 0.25, 0.50, 0.75, 0.97}. At each, re-optimise

    SLICE = c("beta_max", "fert_k", "q10", "rep_dC")

**`rep_dC` is in the slice ON PURPOSE and it is the hypothesis test.** 08-29g §4 proposed, untested,
that the frozen cost is a **CUMULATIVE CO₂ LEVEL OFFSET** — the enhancement takes carbon into the
land pools and returns it over pool turnover times, so repeated eruptions leave the level low, and
the level rows (0.53–0.58 ppm RMS, outvoting everything 40:1) pay. **`rep_dC` IS a CO₂ level bias
(~6 ppm, [[ccx_rep_dc_co2_bias]]), so if the story is right `rep_dC` absorbs much of the cost, and
if it is wrong it will not.** `beta_max`/`fert_k` are the ρ=+0.998 fertilisation pair and `q10` the
temperature sensitivity — the secular compensators.

## 2. GATES

- **H0 — CONTROL.** `gamma_diff` = 0 conditional must return **0.00 ± 0.05** (the slice is already
  at its optimum there). **FAIL ⇒ the optimiser is broken and nothing below is read.**
- **H1 — THE PRICE.** Conditional Δlogpost at `gamma_diff` = 0.25. Bands, fixed here, the 08-29d
  scale: **CHEAP ≤ 20 | MODERATE ≤ 100 | PROHIBITIVE > 100.**
- **H2 — THE LEVEL-OFFSET HYPOTHESIS, and it is a real test.**
  **buy-back ≥ 40 % ⇒ the cost IS largely a level offset** (mostly absorbed by `rep_dC`);
  **buy-back < 15 % ⇒ it is NOT** — the cost is a SHAPE mismatch no level parameter can take, and
  08-29g §4's story is refuted. In between: report, claim neither.
  **PREDICTED: ≥ 40 %**, i.e. the level story holds. ⚠ Registered against the contrary evidence that
  08-29f's ENSO conditional bought back only **2 %** on a nearly identical slice — but that slice
  had **no level parameter in it**, which is exactly the difference this gate turns on.
- **H3 — IS `rep_dC` THE ABSORBER?** Report the fitted `rep_dC` at each γ. If H2 passes, `rep_dC`
  must MOVE ≥ 1 prior-sd by γ = 0.97; if it passes while `rep_dC` sits still, the buy-back came from
  somewhere else and H2's interpretation is void even though its number passed.
  ⚠ **This is the gate that stops H2 being read as a mechanism when it is only an arithmetic.**
- **H4 — DOES THE CORRELATION GAIN SURVIVE REFITTING?** r at each γ, conditionally.
  **PREDICTED: it survives** — r rises to ≈0.62 at γ = 0.25–0.5. **This is the question that decides
  whether the mechanism is worth having at all**, because a gain that vanishes on refit was
  borrowed from the frozen parameters, not supplied by the physics.
- **H5 — GATE 7.** The 2015–2023 land sink at each γ. **PREDICTED: moves < 0.1 GtC/yr**, because
  2015–2023 is volcanically quiet (global AOD ≈ 0.004). A larger move means the enhancement is
  leaving a SECULAR land-uptake bias, which would be a new problem, not a fix.
- **H6 — WHO PAYS.** By-stream decomposition at γ = 0.25, conditional. No gate; a decomposition.

## 3. WHAT NO OUTCOME LICENSES

- **No adoption.** `gamma_diff` stays 0 whatever this says; making it the 22nd FITTED parameter is a
  separate decision requiring a full refit, not a conditional slice.
- **It does not choose a value.** The Pinatubo-matching γ (≈0.97) and the r-maximising γ (≈0.25–0.5)
  differ by 2–4×, and nothing here resolves which target is wanted.
- **It cannot price the mechanism against a RESTRUCTURED model** — plan items ②–⑤ all move the
  objective, and this price is against today's.
