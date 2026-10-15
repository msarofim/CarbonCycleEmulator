# PRE-REGISTRATION — ROUND 5: the cold box's exchange factor under ITS observation; where does the sink go? (2026-09-08e). Written BEFORE launch; binding.

**Ruling (Marcus, 2026-09-08):** "Design round 5, and cancel everything on Torch after the running wave." Round 4's pending
tasks were canceled at 10:50 EDT; ids 0–19 (6 fixed + 14 dispersed) complete or finish by ~12:40 and are the round-4 record.

## What round 4 said (10 of 20; `notes/handoff_2026-09-08d_round4_scorecard_seasonal.md` §6)
`u_hs` freed under the observed overturning went DOWN to 15 m/yr (z −1.48), the likelihood improved +5–7 over round 3, the
export followed (61 gC m⁻² yr⁻¹, ratio 4.0), and **the modern sink was rebuilt in `hs_asx_frac`: 0.82 → 1.83**, nearly its box
top and 2.8× the factor MEASURED from ice × wind × Schmidt (0.653, `data/obs_hs_exchange_factor.rds`, 09-06d) — a parameter
with a box and no prior. ⇒ The sink demand is real and the model has three knobs for it (the flush, the cold-box exchange,
`kz`); pinning one moved it to the next. The 09-08c reading ("the 70 Sv is a sink requirement") was one knob short.

## The space (31 parameters, unchanged count; structure `hilda`; objective #10 + #11)
- **`hs_asx_frac`** keeps its box [0.02, 2.0]; its flat prior becomes lognormal on the measured **0.653**, log-sd **0.15**
  (`data/obs_hs_asx_prior.rds`, `data-raw/build_hs_asx_prior.R`). ⚠ **The width is a JUDGMENT**, 2.8× the measured
  component spread (time windows 0.61–0.66 plus the Schmidt-at-model-T alternative, in quadrature ≈ 0.06). The product's
  other sampled spread — hemispheres, NH 0.32 / SH 0.78, log-sd 0.44 — is the REPRESENTATION error of one factor serving
  two hemispheres, not uncertainty in the global number; at 0.44 the fit would keep 1.83 for 2.7 log-units and the round
  would answer nothing. Round 4's 1.83 sits at **z +6.9**; round 3's 0.82 at +1.5; HILDA's 1 at +2.8. Vetoable.
- `u_hs` and `h_ml` keep round 4's observation priors. Every stored logpost moves again; **compare on LIKELIHOOD**
  (round 3 −1438.64; round 4 leading family −1433.3 / −1432.8).
- **Array 24** (ids 0–5 fixed, 6–23 dispersed) at `%24` = one wave, ~2.5 h at 0.23 s/eval. ⚠ The empirical record
  (rounds 2–4: 40 dispersed draws each, zero new basins) licenses the cut; **R7's power is weaker than a 46-array's and the
  verdict says so.** Outdir `multistart_20260908e_hilda31_asx`.

## THE question, and the reading fixed now
With BOTH `u_hs` and `hs_asx_frac` under observation priors, **where does the modern sink go?** The priced routes:
(a) `u_hs` back up (38 costs 2.6 log-units — the cheapest priced route); (b) `k_w` (lognormal 1500 × 0.4: 2× costs 1.5) /
`kz` (uniform to 27,808); (c) the land (`beta_max` / `fert_k`, judged by gate 7's land row); (d) NO route — the sink is
lost and the CO₂-level, `gcb_ocean_sink` and bomb rows pay.
- **`u_hs` ≥ 33 with the likelihood within 5 of round 4** ⇒ the flush IS the sink's route once the exchange is honest: the
  09-08c reading stands with one more knob closed — DECLARE `u_hs` at the observation and build the missing LS ventilation
  (mode-water) limb.
- **`u_hs` ≤ 27 and the likelihood within 5** ⇒ a third route; NAME it (`k_w`, `kz`, land) and price its own observation.
- **Likelihood worse by > 10** ⇒ no route: the model cannot make the modern sink with an observed cold box — the missing limb
  is proven by exhaustion, and that is the structural finding to build on.

## Predictions
| | prediction | falsified if |
|---|---|---|
| P1 | `hs_asx_frac` at the winner ≤ 0.88 (inside 2σ of 0.653) | > 0.88 (the prior is overruled) |
| P2 | `u_hs` at the winner ≥ 33 m/yr — route (a), the cheapest priced route | < 33 |
| P3 | the export stays ∝ `u_hs`: ratio in [3.6, 4.3] | outside |
| P4 | common-row likelihood within 5 of round 4's −1433.3 (the sink is re-made at similar cost) | worse by > 5 |
| P5 | `kz_deep_frac` recovers toward round 3's 0.025 (K_deep ≥ 150) once the exchange stops carrying the sink | K_deep < 150 |
| P6 | `h_ml` in [45, 100] | outside |
| P7 | unimodal among the 18 dispersed draws: best basin from ≥ 5 starts, basins within 5 agree on `u_hs` to ±5 | otherwise (weaker power, stated) |
| P8 | the sink and bomb rows within 2 of round 4 (`gcb_ocean_sink`, `d14c_NH`, `d14c_SH`) | any > 2 |
| P9 | RECORDED: HS surface δ¹³C, gate Q, `k_w`, gate 7's land row |
