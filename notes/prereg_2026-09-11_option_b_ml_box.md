# Prereg — 2026-09-11. OPTION B: give the mixed layer LATITUDE STRUCTURE (a tropical/subtropical box beside a high-latitude one), from `hilda31p`. Opened on Marcus's ruling that round 6 is REFUTED AS BUILT, MECHANISM RETAINED.

> Status: DESIGN NOTE + PREREGISTERED PREDICTIONS. Nothing built. The build is a fresh session's job
> (weeks-scale per `handoff_2026-09-08j`, §4). Standard: [[ccx_pedagogical_not_emulator]] — the product
> is the CHAIN; a mechanism that buys its observable by breaking a neighbouring link is worse than a miss.

## 0. What round 6 established that this note starts from (all MEASURED, CHANGELOG 2026-09-11)
1. The seasonal mixed layer (`seas_ml = 1`) refits to −1492.16 and is **−17.8 on likelihood** against
   `hilda31p`, ALL of it on `ocean_grad_d13c` (−9.2) and `ocean_grad_dic` (−8.9).
2. **GATE P7 FAILS at 2× its bound**: the modern surface−deep δ¹³C gradient goes −0.309 → +0.018
   (target −0.861; z +3.4 → +5.5); the DIC gradient 302 → 385 (target 233; z +2.1 → +4.7). The
   mechanism homogenises the isotope gradient and steepens the DIC one, both away from the observation.
3. What it BUYS: priors +6.2; `sst_seas_amp_NH` z −2.89 → −2.07 (P2 relaxed, not inside 2σ);
   `ent_seas_amp_SH` 18.7 → 9.5 (P12 half-retired); `pump_hs_gcm2` +2.39 → +1.54.
4. **P1c (09-09p/q)**: the SH ocean has two ANTIPHASE seasonal regimes (thermal subtropics peak Jan,
   DIC-driven Southern Ocean Jul–Aug; hemispheric mean 3.69 µatm vs the Southern Ocean's 16.26, a 4.4×
   cancellation), and the model's `ml` is **84 % low-latitude by area yet is driven by the hemispheric MLD
   climatology** — a low-latitude box given a high-latitude cycle.
5. **Fix B (09-04g, [[ccx_fixB_reservoir_priced]])**: the equatorial-Pacific pCO₂ reservoir sits +55.5 µatm
   above the global mean; the model's representable tropical contrast is EXACTLY ZERO (two hemispheric
   boxes, no tropical one); the observed ENSO ocean sensitivity (+0.1153 ± 0.0246 GtC/yr per Niño3.4
   unit) needs 0.24× that reservoir; the model's solubility-only path is WRONG-SIGNED (r −0.43) and is
   cancelled by four fitted `gamma_enso_*`. **This is THE release blocker, unchanged since 09-03.**

## 1. THE HYPOTHESIS (one sentence)
**Round 6's P7 failure and the ENSO sign error have ONE cause: the single hemispheric mixed-layer box has no
latitude structure.** Winter entrainment is real only where the mixed layer really deepens (the high
latitudes); the ENSO→ocean signal lives only where the thermocline reservoir is (the tropics). One box
per hemisphere forces both mechanisms to act on the WHOLE surface, so the entrainment is ~5× too much
column per unit area and the ENSO response has nothing to modulate.

## 2. THE BUILD (scope; the design choices are Marcus's and are listed as rulings owed)
Per hemisphere, split `ml` into **`ml_lo`** (subtropics + tropics, ~84 % of area, shallow, thermal
seasonal regime) and **`ml_hi`** (poleward of ~40°, ~16 %, the HILDA HS box's surface counterpart or the
HS box itself — RULING 1 below). The tropical upwelling limb of Fix B (T-A0: ~26 Sv, modulated by Niño3.4,
returning through the thermocline) attaches to `ml_lo` (or a dedicated equatorial cell — RULING 2).
`seas_ml` attaches to **`ml_hi` only**, driven by the HIGH-LATITUDE MLD climatology (Holte, poleward
mask — a data-build task), and is OFF on `ml_lo`. The deep column, K(z), the HS/HD boxes and the pump are
untouched (the Δ¹⁴C profile rows must not move — P7-B4 below). Periodic spinup as adopted.
**Rulings owed before building**: (1) is `ml_hi` the existing HS box (cheapest: it already has its own
alkalinity, temperature and pump) or a new box; (2) tropical box or tropical LIMB on `ml_lo`; (3) which
seasonal driver each box gets (SST amplitude per box; the sine path retires?); (4) whether
`ent_seas_amp_SH` survives the build at all (P12 says the mechanism takes half; the rest may be `ml_hi`'s
own entrainment once the box is right).

## 2a. THE FOUR RULINGS — TAKEN 2026-09-11 (Marcus, each on the recommendation; the facts each rested on are cited)
1. **`ml_hi` IS the existing HS box.** Facts: HS is already per-hemisphere, `hs_frac = 0.16` of each hemisphere's
   ocean area (= the ~16 % poleward of ~40°), with its own `alk_hs`, `sst_hs` (2 °C), its own pump (`pump_hs_gcm2`)
   and a fitted `h_hs` over HD (`src/ccx_core.cpp:732-800`). The 09-05 "⚠ NO SEASONAL CYCLE ON THIS BOX" rule
   (`R/model.R:2317`, written to keep fitted LS mechanisms out of a structural test) is LIFTED for `seas_ml`:
   the mechanism moves the HS/HD boundary (`h_hs` ↔ `dz_hd`) mean-preservingly, exactly as it moves ML/layer-1
   today. `ml_lo` = the existing LS mixed layer with `seas_ml` OFF. No new state.
2. **Fix B = a Niño3.4-modulated upwelling LIMB on `ml_lo` first, with a thermocline return** (T-A0's "B");
   a dedicated equatorial box ONLY if PB1 fails on magnitude. Arithmetic: the reservoir's 13.15 µatm over 4.1 %
   of area is the same air-sea flux as 0.64 µatm over `ml_lo`'s 84 % (flux linear in area × ΔpCO₂), so a limb
   can carry the MAGNITUDE; what it cannot do is make the +55.5 µatm reservoir representable — accepted for now.
3. **Drivers: `ml_lo` keeps the fitted SST sines (`sst_seas_amp_NH/SH`); `ml_hi` gets `seas_ml` off a
   POLEWARD-masked Holte MLD climatology PLUS an SST seasonal amplitude PINNED to an observation** (the
   poleward-of-40° SST cycle — a data task beside the MLD one), NOT fitted. No new free parameter beyond the
   build; the 09-05 rule's point (no fitted amplitude inside a structural test) is kept.
4. **`ent_seas_amp_SH` STAYS FITTED in the first B refit; PB3 reads where it goes** (≤ 1.5× centre or → 0).
   Retiring it first would make the test blind ([[no_power_null]]): a free parameter that goes to zero is the
   evidence that `ml_hi`'s entrainment does the shim's job.

## 3. PREREGISTERED PREDICTIONS (state the sign and the bound BEFORE any run; amendments dated)
- **P7′ (the reason this note exists).** With `seas_ml = 1` on `ml_hi` only, **GATE P7 PASSES**: the modern
  surface−deep δ¹³C gradient moves by **< sd_eff (0.16)** from its `seas_ml = 0` value at the same vector,
  and the DIC gradient's move is < its sd_eff (33). ⛔ If it fails again, the box identity was NOT the
  cause and the entrainment formulation itself is wrong — stop, do not retune.
- **PB1 (the blocker).** The solubility-only ENSO→ocean response **flips sign** (r > 0 against the
  observed +0.535) at a physically sized upwelling modulation (T-A0's ~26 Sv), with the four
  `gamma_enso_*` coefficients moving TOWARD zero on refit (their |sum| 0.356 → < 0.18, i.e. they stop
  doing the cancelling). Net sensitivity within 2 se of +0.1153 GtC/yr per index unit.
- **PB2 (P1c resolved by construction).** The SH ocean seasonal ΔpCO₂ shows TWO regimes: `ml_lo` peaks
  near Jan (thermal), `ml_hi` near Aug (DIC); the hemispheric mean cancels toward the observed 3.69 µatm
  while GATE S (the Southern-Ocean phase, [7.41, 10.41]) still passes on `ml_hi`.
- **PB3 (P2/P12 again, and they must do BETTER than round 6, not merely as well).** `sst_seas_amp_NH` inside
  2σ; `ent_seas_amp_SH` within 1.5× its centre (round 6: 1.45×) or retired.
- **PB4 (the deep is untouched).** `d14c_profile_*` and `d14c_mid` rows move by < 1 log-unit each; GATE 7
  (sinks) and GATE G (surface DIC) keep their verdicts.
- **PB5 (likelihood, the 09-09x rule).** Compared on LIKELIHOOD against `hilda31p`: the split must not
  LOSE on the sum of streams; the gradient rows must not lose more than round 6's +6.2 prior gain.
- **PB6 (no free lunch, as in round 6's P6).** The CO₂ seasonal rows at MLO/SPO move by < 1 log-unit.

## 4. What this note does NOT address, and says so
- **`rep_dC` +3.17** — the worst strain in the model, untouched by every ocean option since 09-08 and by
  this one ⇒ [[ccx_rep_dc_co2_bias]]. It is a CO₂-level bias, not a box question. Owed separately.
- **E (the ventilation limb, `kz` 4–40× real)** — the ROOT of the gradient rows' weakness. B is E's first
  advective instance (09-08j); if P7′ passes but the gradient rows are still z +3 / +2, E is next.
- **Gate Q** (air-sea δ¹³C, red at the canonical) — may move with a split box's temperature; REPORT it.

## 5. Provenance
`hilda31p` = `calibration/output/refit_20260910_hilda31_periodic/mode_fit_pumpN.rds` (31 par, hilda,
periodic spinup, `seas_ml` 0). Round 6 = `calibration/output/multistart_20260910_round6_seasml1_sd1.0452/`
(`round6_read.log`, `round6_p7.log`, both collector logs). Gate P7 = `calibration/lib_design_gates.R`
`dg_gateP7_verdict()`, `tests/testthat/test-gate-p7.R`. Memory: [[ccx_round6_result]],
[[ccx_seas_ml_p8_wall_blocks_reference_set]], [[ccx_fixB_reservoir_priced]], [[ccx_assessment_20260908]].
