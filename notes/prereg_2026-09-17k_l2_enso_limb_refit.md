# PREREG (build + array tier) — the LAYER-2 Niño3.4 LIMB as a REFIT on `hilda30h`'s basin (review avenue 1)

**2026-09-17 (k). Written BEFORE any core edit, from HEAD `95c05b7`** (the control refit armed; `hilda30h` canonical). Implements
the whole-model review's avenue 1 (`notes/review_2026-09-16c_whole_model.md` §4 rank 1: "the Niño3.4 layer-2 return limb on the
low-latitude ML as a REFIT — T-A2's geometry; W0 pinned to Meinen 2001; γ prior the observed 14–25 Sv/index") and the 09-17 (i)
handoff's next step. **Every number below is read from the tree today** — the T-A2 scan RE-RUN at `hilda30h`
(`outputs/diagnostics/ta2_enso_return_depth_20260917.{log,rds}`, 12.6 min), the 09-17 scorecard, `data/obs_eq_cell.rds`,
`data/forcing_enso.rds` — or from Meinen, McPhaden & Johnson (2001) *JPO* 31:3230–3248 through that product. Nothing is recalled.
**Nothing is adopted here; the rulings in §0 are OWED before the build starts.**

## 0. Rulings owed (each with the recommendation and what it costs to be wrong)

**R1 — the FORM of the limb.** Three forms exist in the tree:
(a) T-A2's SIGNED ANOMALY exchange between the ML and layer k, no mean, `ΔV = −γ_A·enso`, each tracer on its own gradient
(`calibration/diag_ta2_enso_return_depth.R:66-76`; R session wrapper only, no C++ twin) — the only one MEASURED at k = 2;
(b) the cell / E-loop FLOOR form `W0·max(0, 1 − γ·enso)` with a MEAN W0 (`src/ccx_core.cpp:918-960`, `:1015-1030`) — a mean
limb on the SOLVED pump field is refused by contract (`R/model.R:1528-1536, :3598`: the solved field is a diffusive fixed point
and an advective limb in the column is no longer the operator's fixed point), which is why `w_vent > 0` is inert there;
(c) **RECOMMENDED: the anomaly of the floor form, with W0 entering ONLY through the floor and the unit** —
`ΔV(t) = W0 · (max(0, 1 − γ·enso(t)) − 1)`, `γ = w_enso_l2 / W0`, i.e. `ΔV = −w_enso_l2·enso` while `enso < W0/w_enso_l2` and
`ΔV = −W0` beyond (the upwelling cannot go negative). Zero at `enso = 0` ⇒ the periodic spinup (enso = `FORC_ENSO_PRE1948` = 0)
is BIT-IDENTICAL with the limb on, no fixed-point question arises, and the handoff's "W0 pinned to Meinen, γ in Sv/index" is
implemented literally. The floor binds in **10.4 % of months** (96 of 924, 1948–2024, demeaned index sd 0.751, max +2.29) at the
TOP of the bracket (25 Sv/index over W0 24 Sv ⇒ binds at enso > 0.96) and in **0.3 %** at the bottom (14 over 30 ⇒ > 2.14); so
(a) and (c) differ measurably only near the top of the bracket, and P0e measures that difference rather than assuming it.
**W0 = 27 Sv** (`obs_eq_cell$w0_prior$mean_sv`; Meinen's 24 ± 3 / ~30) as a STRUCTURE CONSTANT `w0_l2`, never fitted.

**R2 — the RETURN LAYER `k_l2`.** The review chose layer 2 on `hilda30c`'s numbers (26.2 Sv/index, "at the TOP of the observed
bracket"). **Re-measured at `hilda30h` today the picture has moved** (§1): layer 2 needs **32.2 Sv/index** — ABOVE the bracket —
and layer 3 needs **17.7** (inside) but costs −15.3 unrefitted, on the CO₂ LEVEL rows. Options: (i) k = 2 as the review
preregistered — the pre-check then PREDICTS the "above the bracket ⇒ the reservoir is needed ⇒ rank 3" outcome unless the refit
lowers the solubility-only magnitude; (ii) k = 3; (iii) both as two arms (two waves). **Recommended: (i), k = 2, ONE wave** — it
is the review's registered geometry, the price is positive, the CO₂-level leak is measured absent (−1.45 at `hilda30c`; today
`co2_level_SPO` +0.80, `co2_icecore` −0.91), and a fitted γ above the bracket is the review's own decision, not a failure of the
prereg. k = 3's −15.3 is a price the refit would have to buy back on `co2_level_MLO` (−5.0), and every return below ~300 m
leaks the index's decadal structure into the level rows at equal interannual slope (T-A2, [[ccx_ta2_return_depth]]).

**R3 — the PRIOR on `w_enso_l2`.** Flat on [0, 60] Sv/index (recommended; the 09-14 (b) precedent for `gamma_eq`: "flat keeps the
verdict's power — the array MEASURES γ; the observation lognormal would pass by construction"), with the Meinen bracket
**14–25 Sv/index as the VERDICT** (§4 PE2), not the prior. Box top 60 = 2.4× the bracket's top and 1.9× today's unrefitted need,
so the mode is not pinned by the box. Alternative: lognormal on the bracket (centre 18.7, log-sd 0.29) — declined for the reason above.

**R4 — the SHIM `gamma_enso_ocn_NH/SH`.** PINNED at 0 in the array (the E-array precedent, `R/calibrate.R:531-532`: "one limb
carries the modulation, option A is subsumed"). The alternative — leave them free and read "→ 0 within 1 se" (the cell's PE2) — is
ill-defined here: `hilda30h`'s SH value sits AT the two-limb kink (`src/ccx_core.cpp:703-705`; its Laplace sd is not a curvature,
`R/paths.R:114-116`). Pinned, the arm has **29 free names** (30 − 2 + 1) and the like-for-like comparison is on LIKELIHOOD
against the canonical's −1400.30 on the same 25 rows ([[ccx_pinned_arms]]).

**R5 — the HEMISPHERIC SPLIT.** Equal Sv per hemisphere (T-A2's; the two cells' areas are 7.41 / 7.36e12 m²). The cold tongue's
reservoir is SH-heavy 1.56× (B1 halves +43.4 / +67.7), but that is the RESERVOIR, which this limb does not represent; a split
parameter would be a second unidentified name (the CO₂ rows see the hemispheric sum; the δ¹³C rows identify the LAND terms).

**R6 — SUBSTRATE and ORDER.** Torch verdict said aloud: fairshare 0.21 on 09-16, channel closed; the Mac ran 24 starts in
10 h 47 min on 09-16 and the control wave occupies it 21:00 tonight → ~08:00. **Mac, the night after the control wave is read**,
from a frozen tree; or Torch if Marcus opens the channel (24 × ≤ 3 restarts × 6000 evals at 0.59–1.08 s/eval is an array).

## 1. Quantitative pre-check (computed BEFORE the build; the array decides)

**What the limb must do.** GCB's ocean sink on annual Niño3.4 with a year term, 1959–2024, n 66: **+0.1153 ± 0.0246 GtC/yr per
index, r +0.488** ([[ccx_fixB_reservoir_priced]] B3; the scorecard's estimator). At `hilda30h`: full model +0.0402 ± 0.0311
(r +0.154) = **0.35× obs**; solubility-only **−0.1873 (r −0.572)**, likelihood −1405.82 ⇒ **the shim is worth +5.52** on the 25
rows (canonical −1400.30). GATE V: sd 0.553 vs 0.933 ± 0.084 (0.59×, z −4.54), deficit **0.380 GtC/yr** (ENSO's knockout share
66 % at ent26; the observed ocean sensitivity supplied 31 % of ent26's 0.213 deficit = 0.066 GtC/yr).

**The scan at `hilda30h` (T-A2's anomaly form, `γ_A` 3 m/yr, both hemispheres; `A_ls` 3.146e14 m² under `hilda_c` ⇒ 1 m/yr =
10.0 Sv; grid at h_ml 65: ML 0–65, k1 65–117, k2 117–190, k3 190–292, k4 292–435 m):**

| k | contrast NH / SH (µmol/kg) | supply (GtC/yr per m/yr) | slope at γ_A 3 | gain (per m/yr) | efficiency | **Sv/index to reach +0.1153** | Δlik unrefitted (rows > 0.5) |
|---|---|---|---|---|---|---|---|
| 1 | +46.0 / +44.5 | 0.175 | −0.1181 | 0.0231 | 0.132 | 130.8 | +2.49 |
| **2** | **+93.8 / +92.5** | **0.360** | **+0.0936** | **0.0936** | **0.260** | **32.2** | **+3.44** (`gcb_ocean_sink` +5.85, `co2_seasonal_SPO` −1.77, `co2_icecore` −0.91, `co2_level_SPO` +0.80) |
| 3 | +128.7 / +127.2 | 0.495 | +0.3231 | 0.1701 | 0.344 | 17.7 | −15.32 (`co2_level_MLO` −5.01, ocean sink −4.04, ice core −2.81, `co2_seasonal_SPO` −2.57, max |Δ¹⁴C row| 1.60) |
| 4 | +163.5 / +161.8 | 0.630 | +0.4709 | 0.2194 | 0.348 | 13.8 | −72.5 (`co2_level_MLO` −22.9, `_SPO` −14.5) |

(At `hilda30c` k2 read +98 / 0.1043 / 26.2 / +2.39 [matched +3.09]. The move: the solubility-only slope worsened −0.1696 →
−0.1873 and the gain per Sv fell 0.01086 → 0.00936, both under `hilda_c`'s +4 K SST and the refit's kz ×1.27.)

**Predictions the array is scored against (k = 2, form (c)):**
- **The unrefitted need is 32.2 Sv/index [29.7, 35.0] at GCB's ±1 se** — 7 Sv ABOVE the bracket's top. For the FITTED value to land
  inside [14, 25] the refit must move the solubility-only slope from −0.1873 to ≥ −0.12 (at 25 Sv/index the limb adds
  +0.234), i.e. the land/ocean ENSO partition and `k_w`/`h_ml` must re-balance by ~0.07 GtC/yr per index. **Prior expectation:
  the fitted `w_enso_l2` lands in (25, 35]** — the review's "above the bracket ⇒ reservoir needed" branch. **Surprise =** inside
  the bracket with the slope reproduced (the limb suffices) OR above 40 (the limb's gain collapses in the refit).
- The price: the limb at its fitted value is worth ≥ the shim's +5.52 on the 25 rows (it carries the same slope with a
  reservoir behind it instead of a free flux): **predicted likelihood ≥ −1400.30** with 29 names; **Surprise =** < −1401.3.
- GATE V: sd rises by **≥ +0.05 GtC/yr** (the 0.066 the observed sensitivity supplied at ent26, scaled by today's 0.35× gap);
  **Surprise =** < +0.02 (the ENSO share of V is not the ocean slope) or the ratio reaching 0.77 (the control's level; V's deficit
  was never mostly ocean).
- The demean flag's worth (`test-enso-demean`'s price, 17.5455 at `hilda30h`, 41.6102 at the control) rises: **predicted ≥ 30**.
- The CO₂-level rows: |Δ| < 2 log-units each vs the canonical (T-A2 k2: −1.45 at `hilda30c`; +0.80 / −0.91 today).
- The deep: kz, `pump_grad`, the three Δ¹⁴C profile rows each within 1 posterior σ of the canonical (the limb has zero mean — it
  cannot move a mean gradient; measured today max |Δ¹⁴C row| 0.59 at γ_A 3 = 30 Sv/index).

## 2. What is built — ONE fitted name, two structure constants, both cores

**Fitted.** `w_enso_l2` — **Sv per Niño3.4 unit, WHOLE-BAND (both hemispheres, split equally)**; `tr = "logit"`, box **[0, 60]**,
init **18.7** (the bracket's geometric centre), prior flat (R3). Joins `CCX_PARAM_ABSENT_OK` (`R/calibrate.R:1067`): absent from
every registered file = 0 = no limb, seeded at init by `ccx_mode_start()`. ⛔ Name check: prefixes nothing in the table
(`w_eq`, `w_vent`, `w_thc`, `w_up`, `w_out_*` — the `w_e` → `w_eq` incident; `test-mode-struct-lint`).
**Structure constants** (in `CCX_STRUCT_HILDA` and inherited by `hilda_c`, range-checked BY NAME like `q_attach_from`):
`k_l2 = 2` (R2), `w0_l2 = 27` Sv (`obs_eq_cell$w0_prior$mean_sv`; R1). Neither reaches `u`.
**The limb (per hemisphere `h`, inside the hemisphere loop, AFTER the base derivative; `enso = f[5]`, demeaned + tapered):**
```
gam   = w_enso_l2 / w0_l2                                  # per index unit
fac   = max(0, 1 − gam·enso(t))
dV_h  = w0_l2 · SV_TO_M3YR · share_h · (fac − 1)           # m³/yr, ≤ 0 in El Niño, share_h = 1/2
for each tracer: F_tr = dV_h · ( y[k_l2, tr] / (a_ls[h]·dz[k_l2]) − y[ml, tr] / (a_ml[h]·h_ml(t)) )
                 dy[k_l2, tr] −= F_tr ;  dy[ml, tr] += F_tr
```
i.e. an exchange of EQUAL volume each way on the two boxes' true per-volume concentrations (the conduit's lesson; identical to
T-A2's difference form, `diag_ta2_enso_return_depth.R:70-73`, and to the cell's up/down limb pair at equal W). `h_ml(t)` is the
SAME thickness the ML's own limbs use at t (seasonal under `seas_ml`). Bulk transport only (α = 1; ¹⁴C unfractionated by
convention). No pump, no air–sea, no change to the solved field. **C++ twin** in the E-loop's position (`src/ccx_core.cpp:1015`),
`Par` field `w_enso_l2`, `Aux` fields `k_l2`, `w0_l2`, marshalled BY NAME through `ccx_cpp_par()` / `ccx_cpp_aux()`
(`R/cpp.R:240-260, :355`), zero-filled when absent. R twin beside the E loop (`R/model.R:3136`). `enso` needs no forcing change.
**Contracts (P0, each a test, each MUTATION-tested — break the guarded thing and the test must fail):**
- **P0a ABSENT = BIT-EXACT**: `w_enso_l2` = 0 (and absent) reproduces `hilda30h`'s `y` `expect_identical` in BOTH cores; its stored
  streams to 1e-12; the port targets unchanged.
- **P0b SPINUP UNTOUCHED**: the periodic spinup with `w_enso_l2` = 25 is bit-identical to the canonical's (enso = 0 there).
- **P0c CONSERVATION**: total carbon and each isotope conserved to 1e-12 over the transient with the limb at 25 (equal volumes).
- **P0d PARITY**: R vs C++ at `w_enso_l2` = 25, every box every tracer, rel < 1e-10, and identical `add_flux` labelling (the
  flux trace counts it in `ocean_net`, as the shim is).
- **P0e THE FLOOR**: at 25 Sv/index the floor binds in 10.4 % of months (measured on the forcing, §0 R1); the slope from the
  floor form vs the unclipped linear form differs by < 10 % — RECORDED, and if larger, the array's verdict names it.
- **P0f REFUSALS BY NAME**: `k_l2` outside 1..nl errors; `w0_l2` ≤ 0 errors; the limb with the cell on (`eq_on`) or the E loop on
  is refused (two upwelling representations on one column).

## 3. Likelihood changes — NONE
The same 25 rows, the same σ table, objective #12. The verdict's instrument is the 09-04g ENSO regression
(`calibration/lib_enso_regression.R`; annual ocean uptake ~ year + Niño3.4, 1959–2024) read by the scorecard, plus GATE V and
`test-enso-demean`'s price. No new row: the reservoir (B1) is NOT represented by this limb and is not scored.

## 4. Predictions and the decision rule — in the PHYSICAL unit, stated before the run
**P0 first (§2); nothing below is read if P0 fails.**
**PE — the unrefitted probe** (Mac, `calibration/diag_l2_enso_limb_probe.R`, at `hilda30h` with the shim set to 0, `w_enso_l2` ∈
{0, 14, 18.7, 25, 32, 40}; ~2 min per point):
- **PE1**: slope monotone in `w_enso_l2`, r flips positive by 18.7, the observed slope reached within [28, 36] Sv/index (the scan's
  32.2 ± the floor's clipping). N1 = the 0 point reproduces the solubility-only line (−0.1873, r −0.572, lik −1405.82) exactly.
- **PE2** (probe): the CO₂-level rows move < 2 log-units at 25.
**PA — the ARRAY** (24 starts, `CCX_MS_STRUCT=hilda_c CCX_MS_SEAS_ML=1`, pins = the canonical's 7 + `gamma_enso_ocn_NH=0,
gamma_enso_ocn_SH=0` ⇒ 29 free; the reference set needs a branch in `ccx_ms_reference_set()`: incumbent = the canonical at its
point with the shim zeroed and `w_enso_l2` seeded, new basin = `hilda31p` likewise; port targets regenerated; spread 1.0452;
300/3/6/6000 like every wave since 09-14). Read by `collect_dispersed_multistart.R` + the scorecard at the derived mode:
- **PA1 — THE VERDICT (physical unit)**: fitted `w_enso_l2` with its Laplace sd.
  **PASS** iff **14 ≤ ŵ ≤ 25 Sv/index** AND the ENSO ocean slope is within 2 se of GCB (**[0.066, 0.165]**) with r > +0.25 AND
  likelihood on the 25 rows ≥ **−1401.3** (the canonical's −1400.30 less AIC's one log-unit per name for the one name fewer —
  the limb REPLACES the shim's +5.52 or it is not a replacement).
  **PARTIAL — "the reservoir is needed"** iff 25 < ŵ ≤ 40 with the slope and likelihood conditions met: the limb is right-signed and
  sufficient only above the observed modulation ⇒ the review's rank 3 (the tropical column / cell) is the next build, and the
  limb stays as a registered comparison arm, NOT canonical.
  **REFUTED** iff ŵ > 40, or the slope < 0.066, or likelihood < −1401.3, or any of PA3–PA4 fails: the layer-2 limb is not the
  ENSO-ocean mechanism in this class; `gamma_enso_ocn_*` is un-pinned and the shim stands until rank 3.
- **PA2**: GATE V sd ≥ 0.603 (+0.05) — soft (non-blocking by ruling); recorded either way.
- **PA3**: `co2_level_MLO/SPO`, `co2_icecore` each within 2 log-units of the canonical's streams; `d13c_level_*` within 3.
- **PA4**: kz, `pump_grad`, `kz_deep_frac`, the three Δ¹⁴C profile rows, `ocean_grad_dic` each within 1 posterior σ of the
  canonical (the limb has no mean; the deep must not move).
- **PA5**: the land ENSO pair `gamma_enso_land_NH/SH` moves < 1 posterior σ (the δ¹³C rows identify them; the ocean fix should
  not be bought with the land).
- **PA6**: `test-enso-demean`'s price at the derived mode ≥ 30 (from 17.5455).
- **PA7** (sensitivity, after the read): the matched arm at k = 3 for ONE start from the derived mode (not an array) — records
  whether the bracket is reachable one layer down at what price on `co2_level_MLO`.
**Promotion is Marcus's ruling in every branch; a PASS is scored, not adopted.**

## 5. What is explicitly NOT claimed
Not that the limb IS the equatorial cell (no reservoir, no cold-tongue SST, no B1 row — the +55.5 µatm excess stays
unrepresented; the T-DIC lesson does not arise because no box changes temperature). Not that 14–25 Sv/index is the modulation
in an annual regression (Meinen's swing is a monthly peak-to-peak over ONE event; the annual-mean conversion is 2.00 index units
— `obs_eq_cell$w0_prior$note`); the bracket is a verdict band, and "above it" is a finding about the reservoir, not a refutation
of the physics. Not that GATE V closes (ENSO is 66 % of its knockout at ent26 but the model has 33 % of the observed interannual
variance and "louder is not righter", [[ccx_gate_v_variability]]). Not a hemispheric split (R5).

## 6. Order and artefacts
Rulings R1–R6 → param table + structure constants + `CCX_PARAM_ABSENT_OK` → R limb → C++ twin + marshalling → `test-l2-enso-limb.R`
(P0a–P0f, mutation-tested) → suite on a frozen copy (the standing reds only) → the unrefitted probe (PE1–PE2, N1;
`outputs/diagnostics/l2_enso_limb_probe_2026MMDD.{log,rds}`) → `ccx_ms_reference_set()` branch + `test-ms-reference-set` →
port targets → bundle → frozen tree → Mac preflight 24/24 → the wave (after the control wave is read) → collect → PA1–PA6 →
PA7 → the ruling. Every gate reads the canonical THROUGH the registry ([[ccx_canonical_mode_one_place]]); every number in the
read carries the arm's label (struct, seas_ml, pins, `k_l2`, `w0_l2`) and the commit.

## 7. AMENDMENT after the build and the unrefitted probe (same day; nothing above is edited)
**Built** (`fd61c02`): rulings R1–R6 taken as recommended. One deviation from §2: the two structure constants live in
`ccx_default_params()` (`k_l2` **0** = absent, `w0_l2` 27) and the new label **`hilda_cl2`** = `hilda_c` + `k_l2` 2, so every
registered structure keeps the limb ABSENT and `w_enso_l2` INERT there (⇒ `CCX_PARAM_ABSENT_OK`, pinned in any array without the
limb; the driver refuses it free under `k_l2` = 0). P0a–P0f: `test-l2-enso-limb.R` 112/0 (both cores; the canonical's 25 rows
bit-exact; parity 1e-10; the floor and the physical unit asserted against `w × SV × ½ × (c_k − c_ml)`).

**Probed** (`calibration/diag_l2_enso_limb_probe.R` → `outputs/diagnostics/l2_enso_limb_probe_20260917{,_k3}.{log,rds}`, 6 s each):
gate 1 reproduces (5.8e-11); N1 reproduces the 09-17 scan's solubility-only line (−0.1873 / −0.572 / −1405.82) exactly; the
UNCLIPPED form at 25 Sv/index (+0.0467) reproduces the T-A2 R-wrapper's gain — the C++ build agrees with the independent
session device.

**Two findings the pre-check (§1) did not anticipate:**
1. **The floor costs a THIRD of the response at k = 2.** At 25 Sv/index the clipped slope is +0.0314 vs +0.0467 unclipped
   (32.7 % apart) although the floor binds in only 7.9 % of months — those months are the large El Niños that carry the
   regression. So the observed slope is reached at **37.0 Sv/index [33.8, 40.1]** with the floor (32 linear), r flips at 22.2,
   and Meinen's bracket [14, 25] delivers only [−0.55, +0.19]× obs. **PE1 FAILS at k = 2** on two of three clauses (r at 18.7
   = −0.063; the need 37.0 outside [28, 36]); PE2 PASSES (level rows −0.42 / −0.14 / −0.42 at 25). The pre-check's band
   [29.7, 35.0] was the LINEAR need; the floor's clipping was measured (§0 R1) but its leverage on the regression was not.
2. **`co2_gradient` is −1.6 at EVERY w** (k = 2 and k = 3 alike): the shim's inverted split (NH 0.36 / SH 0.00) was buying
   the interhemispheric CO₂ gradient row, which an equal-split limb (R5) cannot. A second thing the shim did that the review
   did not name.

**The k = 3 sensitivity (PA7, run unrefitted now because it costs 6 s):** the observed slope at **19.3 Sv/index [17.6, 21.0]** —
INSIDE the bracket; r +0.317 at 18.7; the floor 6–10 % apart from linear (it binds in 4 % of months at the need); price vs the
canonical **−5.0 at 18.7** (`co2_level_MLO` −1.9, `co2_gradient` −1.7, `co2_icecore` −1.3, ocean sink −0.8), vs −15.3 in the
T-A2 scan at an OVERDRIVEN 3 m/yr; at 25 it is −10.3 and PE2 fails (`co2_level_MLO` −2.7). The two layers at a glance:

| k | need (Sv/index) | inside 14–25? | Δlik vs canonical at the need | level rows at the need |
|---|---|---|---|---|
| 2 (117–190 m) | 37.0 [33.8, 40.1] | NO | ≈ −3 | inside 2 |
| 3 (190–292 m) | 19.3 [17.6, 21.0] | YES | ≈ −5.5 | `co2_level_MLO` ≈ −2 |

**What this changes (a RULING, not a decision taken here):** ruling R2 (k = 2, the review's geometry) was taken on the pre-check's
32.2; with the floor the layer-2 limb cannot reach the observed sensitivity inside the observed modulation even before the refit
trades anything, which is the PARTIAL branch of §4 PA1 predicted with near certainty. Layer 3 reaches it inside the bracket at
a price the refit can plausibly re-balance (the level rows, ~2 log-units each). Options for the array: (a) k = 2 as
preregistered (the array then measures how far above the bracket the refit lands); (b) **k = 3** (recommended: the only
layer that puts the bracket and the slope in the same place; PA3's level-row bound stays the test); (c) both, two waves.
Nothing is launched until ruled.
