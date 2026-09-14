# PREREG (scoping tier) — the equatorial cell's SECOND build: the T–DIC mismatch

**2026-09-14 (c). Written BEFORE any core edit, from HEAD `317fc9f` (the launch tree `11e2b7a` + the 09-14 review fixes +
the first array's results). `hilda30c` stays canonical; `hilda30e` is NOT promoted; `w_eq`/`gamma_eq` stay on `CCX_PARAM_ABSENT_OK`.**
Every number here is from `calibration/diag_eq_cell_levers.R` → `outputs/diagnostics/eq_cell_levers_20260914.{log,rds}` (at the
first array's best vector, `start_011`), from the first array (Torch 17769990, `collect_round1.log`), or from `data/obs_eq_cell.rds`.
Rulings needed are marked **R**; nothing below is built until they are taken.

## 0. What the first array said (the baseline this build must beat)
- Best −1450.518 (10 tasks, id 0 CONVERGED); `w_eq` **10.72 Sv = z −5.4** on Meinen's 27 ± 3 (PE8 FAIL); `gamma_eq` 0.600 (PE7 PASS by
  the number, but **6.4 Sv per index vs the observed 14–25**); B1 at the fit **+73.4, z +2.65**; ENSO ocean slope **1.12× obs, r +0.44**
  (with `gamma_enso_ocn` still 0.20 / 0.13); the 25 common rows −0.46 vs the canonical; `pump_grad` 314 → 258 in every basin.
- The pair is invariant across the `h_ml` ridge (74 / 70 / 65 / 50 m within 3 log-units): the data pin it independently of the basin.

## 1. The hypothesis, measured
**At W0 = 27 Sv the cell's pCO₂ excess is the model's mixed-layer DIC exposed at the cell's temperature, not upwelled carbon.**
The single low-latitude mixed layer (0–57°) holds ONE DIC (PI annual mean 1989 / 2006 µmol/kg NH / SH) equilibrated at its
18 / 16 °C. The cell's loop returns that water through layer k and exposes it at 27.04 °C. Decomposition of the PI excess, annual
means over the mass at the time (the ruled reader), `pCO₂(DIC_ml, T_eq) − pCO₂(DIC_ml, T_ml)` = the T-term, the rest the DIC-term:

| case (all `w_eq` 27 unless noted) | B1 model | z | excess NH / SH | T-term NH / SH | DIC-term NH / SH | ENSO slope / obs |
|---|---|---|---|---|---|---|
| the FIT (`w_eq` 10.72, γ 0.60) | +73.4 | +2.65 | +61 / +67 | +125 / +160 | −64 / −93 | 1.12× |
| `w_eq` 27, else the fit | **+133.2** | **+11.5** | +116 / +128 | **+124 / +159** | −8 / −31 | 2.42× |
| cell 2 °C colder | +116.9 | +9.1 | | +93 / +126 | +7 / −14 | 2.33× |
| cell 4 °C colder (the cold tongue) | +101.5 | +6.8 | | +65 / +94 | +21 / +2 | 2.24× |
| `k_eq` = 1 | +103.5 | +7.1 | | +125 / +160 | −38 / −62 | 1.19× |
| `k_eq` = 1 and 2 °C colder | +88.2 | +4.8 | | +94 / +126 | −22 / −43 | 1.10× |
| **cell AT the ML's SST (T-term off)** | **+60.7** | **+0.76** | +44 / +55 | −12 / +12 | **+56 / +43** | 1.89× |

Reading: at 27 Sv the cell's DIC is already BELOW the mixed layer's (it has degassed); the whole +133 is the T-term. Remove the T-term
and the upwelled thermocline contrast alone gives **+61 at Meinen's transport — inside 1σ of the +55.5 observation**. The fit reached
+73 by STARVING the cell (10.7 Sv) until its DIC deficit (−64 / −93) cancelled most of the T-term. Cold surfacing is worth 7.9 µatm
per °C; `k_eq` = 1 is worth −30; both −45 — each a quarter of the gap. **Neither is the lever. The lever is the DIC of the water the cell
exchanges with: it must be equilibrated warm.** (The real band surface has DIC 1983 at 27 °C — GLODAP `obs_eq_cell$dic_eq$surface` —
against the model's 1989 at 18 °C: the same DIC, ~9 °C apart, is the +130.)

## 2. Design options — RULED 09-14 (d): R1 = T1; R2 = the isotherm (value: Marcus's pick after the measurement in CHANGELOG 09-14 (d); recommended 26 °C); R3 = `seas_ml` OFF first, ON as the registered follow-up; R4 = `q_tr` = 0 first, "structural from an observation" a LATER test paired with the `seas_ml`-on follow-up
(The options as written before the rulings, for provenance:)
- **T1 — a TROPICAL SURFACE BOX `tr` per hemisphere** (mirror boxes, one parameter set — the cell's own precedent): area from a mask
  (0–~20°, R2: the latitude bound, from the SST/ice climatology, not typed), SST the band's observed mean, own air–sea, own alkalinity
  (GLODAP), a seasonal cycle only if the data product has one (small in the tropics — R3: `seas_ml` on `tr` or not). The cell's loop
  closes THROUGH `tr`: `oc[k_eq] → eq → tr → oc[k_eq]`; `tr` exchanges with the remaining `ml` (now ~20–57°) by an exchange volume
  `q_tr` (R4: fitted with a prior, or structural from the tropical cells' poleward Ekman divergence — the same Meinen transport in a
  different role). Structure label **`hilda_tr`** (HILDA + cell + tropical box). The surface readers (`ocean_grad_*`, B1's "all
  surface", `hs_surf`) take `tr` by area like they took `eq`; `ccx_box_annual_conc` needs `which = "tr"`.
  Cost: two boxes, a geometry product (`data-raw/build_tr_box_targets.R` → `data/obs_tr_box.rds`), both cores, the readers, ~150
  expectations. The ML's ENSO SST anomaly and the seasonal ML mechanics are UNCHANGED on `ml`; `tr` gets the cell's SST-anomaly idiom.
- **T2 — the subduction limb returns the ML's DIC minus its T-equilibrium offset** (a shim: DIC corrected to the cell's Henry point).
  Declined on the shim precedent (`ent_seas_amp_SH`): it stands in for a mechanism and prices nothing.
- **T3 — the cell's air–sea at the ML's SST** (the counterfactual above). Not physical; it is the MEASUREMENT of the hypothesis, not a build.
- **T4 — cold surfacing / `k_eq` = 1 alone.** Measured insufficient (§1); they remain refinements AFTER T1.

## 3. Predictions (registered now; read on T1's array)
- **PT1**: with T1 at `w_eq` = 27 Sv, γ 0.6, unrefitted, B1 lands within **2σ of +55.5** (the counterfactual says +61). FAIL above +69 ⇒ the
  tropical box's DIC does not equilibrate warm enough (its exchange with `ml` too fast) or the source contrast is wrong.
- **PT2**: the fitted `w_eq` lands **inside Meinen's 2σ (21–33 Sv)** — PE8 re-run; this is the number the build exists to move.
- **PT3**: the fitted `gamma_eq` DROPS below the first array's 0.60 — the counterfactual's ENSO slope is 1.89× obs at 0.6, so ~0.3–0.35
  per index = **8–9.5 Sv per index, BELOW the observed 14–25 bracket**. A registered tension, the other way round from PE7: if it
  lands there, the cell's ENSO gain per Sv is too large (residence time `h_eq/W`, or the source layer too DIC-rich), and `k_eq` /
  `h_eq` are the next levers.
- **PT4**: `pump_grad` returns toward the canonical's 314 (the first array's −18 % was the cell degassing what the pump held).
- **PT5**: the 25 common rows move < 2 log-units vs the canonical (D1's area accounting on `tr` is the risk, as PE5 was for `eq`).
- **PT6**: `tr`'s own surface DIC / δ¹³C land inside GLODAP's tropical band (the PE6 idiom, on the box).
- **N-T1** (negative control): `q_tr` → ∞ (tr ≡ ml) reproduces the first build's +133 at 27 Sv to 1 %.

## 4. Not claimed
Not that T1 fixes GATE V; not that the observed 14–25 Sv per index is reproduced (PT3 predicts it is NOT); not that `h_ml`'s ridge
resolves; not that the SH-heavy asymmetry (PE9) is representable. The first array's mode (`start_011`) is provenance, never a canonical.

## 5. Order
R1–R4 → geometry product → R side → C++ twin → tests (P0-style contracts: no-op at `tr_frac` 0, conservation, parity, reader no-op,
N-T1) → unrefitted probe (PT1, PT6) → one Torch array under `hilda_tr` (33 + `q_tr` if fitted) → PT2–PT5.
