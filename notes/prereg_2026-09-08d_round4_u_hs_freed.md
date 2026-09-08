# PRE-REGISTRATION — ROUND 4 of the HILDA refit: `u_hs` FREED under the observed overturning, `h_ml` under the Holte mean/max prior (2026-09-08d). Written BEFORE launch; binding.

**Ruling (Marcus, 2026-09-08):** "Free u_hs. Either free h_ml or explore pinning it to a seasonal shape so that it can
capture both the annual mean and the annual max." The seasonal shape is scoped, not built
(`notes/options_2026-09-08d_seasonal_h_ml.md`, the round-5 candidate); round 4 takes the "free" branch for both.
Context: `notes/handoff_2026-09-08c_u_hs_h_ml_tests.md` — the CO₂-level rows hold `u_hs` at 38 (fixed export: 24 m/yr
costs 189; sink 3.03 → 2.88 GtC/yr) while the deep rows alone want the HS export ∝ `u_hs` (96 gC m⁻² yr⁻¹ at 24).

## The space (31 parameters; structure `hilda`; objective #10 + #11 as round 3)
- **`u_hs`** enters `CCX_PARAM_TABLE` after `h_hs` (30 → 31): logit on [5, 150] m/yr; prior lognormal median **21.84**,
  log-sd **0.242** (`data/obs_u_hs_prior.rds`: NADW 18 Sv + AABW 16–29 Sv = 34–47 Sv over the model's HS area 5.776e13 m²;
  the AABW estimate's own error in quadrature). The former declared 38 sits at **z +2.29** (a 2.6 log-unit prior cost).
  Ancestors migrate to 38 (what they ran), which encodes, so every reference start begins AT 38.
- **`h_ml`** keeps its box [30, 200]; its flat prior is replaced by lognormal median **83.9 m**, log-sd **0.341**
  (`data/obs_h_ml_prior.rds`: the LS annual mean 59.7 and annual max 118 are the 16/84 % points). 39.8 sits at **z −2.19**.
- Removed from `CCX_STRUCT_HILDA`: `u_hs`. Everything else as round 3 (`pump_hs_gcm2` literature prior, `h_hs` free,
  `hs_asx_frac` free, `q_attach_from` 1, `kz_zscale` 253, `tau_q` 538, `sst_hs` 2, `hs_frac` 0.16).
- Harness as round 3: 46 starts (ids 0–45 at `%10`), 3 restarts × 6000 maxit × 6 cycles, wall 180 min, port gate at
  1e-8. Output `calibration/output/multistart_20260908d_hilda31/`. ⚠ Every stored logpost moves (two priors changed):
  **compare on LIKELIHOOD**; round 3's winner is −1438.64 on the same rows.

## THE question, and the reading fixed now
Round 4 is a ONE-question experiment: **does the fit run `u_hs` back toward 38 against a prior that says 22?**
- If the winner's `u_hs` ≥ **33 m/yr** (z ≥ +1.7): the CO₂ record overrules the overturning — **the 70 Sv flush is a
  structural requirement of the sink** in a model whose LS column ventilates only by `kz`. The finding is then about
  the missing mode-water limb (SAMW/AAIW subduction), not about `u_hs`; the next design is a ventilation path for the
  LS column, and `u_hs` should be declared at the observation with that path added.
- If the winner's `u_hs` ≤ **27 m/yr** (z ≤ +0.9): the observation holds once the rest refits; the export falls with
  it (R2) and the deep is bought at half the price. Adopt-worthy on likelihood.
- Between 27 and 33: the two are in contest; report the profile and do NOT adopt.

## Predictions (the run is judged on these)
| | prediction | falsified if |
|---|---|---|
| R1 | the winner's `u_hs` ≥ 33 m/yr (the CO₂ rows win: T1(i)'s 189 at 24 dwarfs the prior's 2.6) | `u_hs` < 33 |
| R2 | `pump_hs_gcm2` at the winner = (3.6–4.3) × `u_hs` (T1(ii)'s ratio 3.82–4.11 ± 5 %) | outside |
| R3 | `h_ml` at the winner in **[50, 100]** m (the prior pulls 40 up; the likelihood's refit-level slope is ~4 over 40 → 184) | outside |
| R4 | LIKELIHOOD on the common rows within **5** of round 3's −1438.64 | worse by > 5 |
| R5 | conditional: if `u_hs` < 30, the HS surface δ¹³C < +2.40 (T1(ii): 2.48 → 2.38 as `u_hs` falls) | `u_hs` < 30 and δ¹³C ≥ 2.40 |
| R6 | the three Δ¹⁴C profile rows inside 2σ | any |z| ≥ 2 |
| R7 | unimodal: the best basin reached from ≥ 10 of 46 starts, all basins within 5 of it agree on `u_hs` to ±5 m/yr | otherwise |
| R8 | `gcb_ocean_sink`, `d14c_NH`, `d14c_SH` each within 2 of round 3 | any moves by > 2 |
| R9 | RECORDED, not predicted: GATE Q (air-sea δ¹³C disequilibrium; round 3 FAILS at 2.17σ, `ent26` passes at 1.27) and the HS surface δ¹³C — the 2 °C fractionation question stays open |
| R10 | `kz_deep_frac` and `hs_asx_frac` stay within 30 % of round 3's (0.0247 / 0.818): `u_hs` does not simply trade against them | either moves > 30 % |

## What is NOT changed, so it cannot be blamed
Objective rows, σ's, the export prior, the HS-surface rows, the structure's declared values, the harness budget. The
seasonal mixed layer (option B) is deliberately NOT in this round so the `u_hs` answer is attributable.
