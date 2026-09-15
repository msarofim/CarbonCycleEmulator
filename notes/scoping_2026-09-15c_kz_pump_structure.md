# SCOPING — the kz / PUMP STRUCTURE after the 09-15 (b/c) diagnosis: what holds kz, what the export is, and the options

**2026-09-15 (c). From the prereg `notes/prereg_2026-09-15b_kz_pump_diagnosis.md` (A1–A3 stamped) and its reads
`outputs/diagnostics/kz_pump_pathways_20260915.{log,rds}` and `kz_pump_scan_20260915.{log,rds}` (CHANGELOG 09-15 (c)).
Every number is from those logs. Nothing is adopted; `hilda30c` canonical; rulings owed (§4).**

## 1. What was measured
**The bomb-¹⁴C carrier (PK-1).** At 1975, of the excess ¹⁴C delivered into the interior: LS ML-base diffusion 51 % + entrainment
19 % = **70 %**, the LS pump **19 %**, the HS route 12 %; the conduit ≈ 0 to the upper layers. The 09-14 (g) reading "diffusion
carries the bomb ¹⁴C" is CONFIRMED for the bomb-peak decades, and the cold column is not the carrier. But the pump's share grows to
32 % (1995) and **41 % (2010)** while diffusion's cumulative delivery REVERSES after 1995: on the WOCE/GLODAP horizon the one-way
45.6-GtC/yr export is the largest single carrier. The canonical's ocean bomb inventory overshoots Peacock + Key — 60.3 / 82.8 kmol
vs 48.6 ± 10.7 / 51.4 ± 10.8 at 1975 / 1995 (z +1.1 / **+2.9**) — and the pump delivered 22.7 of the 31.4-kmol 1995 overshoot.

**What holds kz (PK-2).** With the CO₂ record held by the land three (arm B), kz × 0.5 costs −295: the atmospheric bomb rows
−202, the modern ocean sink −28, `d14c_profile_level` −28 (the K(h_ml) = kz anchor drags K_deep), the δ¹³C level rows **−4.4**
(P2B's δ¹³C prediction REFUTED — δ¹³C does not hold kz; the E array's −29 there was not a kz cost). With the ¹⁴C nuisances and
the surface names also freed (arm C: `sigma_d14c` 5.5 → 7.5, `bomb_total` 118 → 114, `h_ml` 65 → 75, `kz_deep_frac` 0.012 → 0.033),
kz × 0.5 costs **−86** and kz × 0.7 only **−19**; the survivors are the ocean sink (−21 / −7), `d14c_SH` (−22 / −6) and the SPO
seasonal CO₂ amplitude (−13 / −5). ⇒ kz's hold is SOFT at −30 %, spread over the fast-exchange / capacity rows, and there is no
lower-kz basin under this structure. The E array's kz 8,615 (× 0.79) sits inside the soft region — the refit did not "fail to lower
kz"; there was ~nothing to gain by lowering it further.

**What the export is.** Under the solved field the export is `div(K · dC)` at the PRESCRIBED PI gradient (`R/model.R:3284`):
15.9 / 22.7 / 31.8 / **45.5** / 63.6 GtC/yr at kz × 0.35 … 1.4, with the modern DIC-gradient row UNMOVED (302.4–303.2). No scored
row demands 45 GtC/yr; the only row that SEES the export's carbon is `excess_c14_ocean`, which prefers less (+1.4 at kz × 0.5) and is
wide (σ 10.7 kmol). The export cannot reach the observed 5–13 GtC/yr along kz (that needs kz ≈ 2,200; arm B −720 at × 0.35 and
steepening). **The export is a consequence of the field's construction — a diffusive column with K_deep 129 holding a 314-µmol/kg
gradient — not a fitted quantity and not a demand of the data.**

**The deep K (PK-3).** The E mode's `kz_deep_frac` 0.089 costs −124 unrefitted at the canonical kz, `d14c_profile_ab` −49 (the deep
A−B contrast collapses) and the CO₂ rows −57; the E refit bought it with `h_ml` 38 m and the `hs_asx_frac` lean.

## 2. What this closes
- Root cause (1) of the 09-14 (g) review is now three separate facts, not one chain: (a) diffusion at the ML base is the bomb
  carrier through 1975 and kz is held, softly, by the sink / bomb / seasonal-capacity rows; (b) the 45-GtC/yr export is the solved
  field's response to (a) against a prescribed PI gradient, demanded by nothing; (c) the warm-box exposure of cold-equilibrated DIC
  (the cell's +133, tr's +68) follows from (b) at any kz in the soft region.
- Option E's failure is explained: prescribing the export removed (b) but the column then needed the gradient held by K_deep
  (× 5.9, −124 on the deep rows) because the model has NO ADVECTIVE DEEP RETURN — the pile-up below 900 m (N-E1) is the diffusive
  column's only way to hold a prescribed field. That is the structural gap, and it is the same gap T-A0 / T-A2 met from the other
  side (a return limb's DEPTH decides its price: −135 on `d14c_profile_bd` at the bottom, +3 at layer 2).

## 3. Options (priced where a measurement exists; none recommended over Marcus's judgement)
- **O1 — prescribed export WITH a mean deep return limb.** `pump_field = "martin"` (built) + a steady upwelling limb returning
  deep water through the thermocline (the real ocean's balance: export down, ~20–30 Sv up). The design axis is the RETURN DEPTH
  (T-A2's lesson; the E loop returned from layers 1–3 and was inert at 0.065 /yr against kz's 3 /yr). Price unknown as a refit;
  the unrefitted brackets are T-A0's −135 (bottom return) and T-A2's +3 (layer-2 return). Would be the first structure in which
  the export is an OBSERVATION (Nowicki) rather than a consequence. Cost: a build + a Torch array (~1 session + 5 h).
- **O2 — accept and DOCUMENT (the pedagogical reading).** CCX is a pedagogical model, not an emulator ([[ccx_pedagogical_not_emulator]],
  Marcus 09-03). State in DESIGN §6 that the diffusive column's export at the fitted K is 45 GtC/yr against an observed 5–13, that
  no scored row constrains it, that the model has no advective deep return, and that the warm-box excess follows. Price 0; the cell
  / T5 arcs continue on their own terms with this as a known limitation of the reservoir they read.
- **O3 — make the one row that sees the export bite.** `excess_c14_ocean`'s σ (10.7 kmol) — if it is the product's own, nothing to
  do; if it is a judgement width, re-deriving it is legitimate, re-weighting a row to force a structure is not. Not recommended as
  a lever; recorded because it is the only observational handle on the export inside the objective.
- **O4 — the K(h_ml) = kz anchor.** `d14c_profile_level`'s charge along kz is the parametrisation (K_deep = kz·f); freeing `f`
  removes it (arm C). A note for any future kz frontier, not a build.

## 4. Rulings owed
1. O1 vs O2 (or both: O2 now, O1 as the next build). 2. Whether T5 / the cell resumes under O2's stated limitation, or waits for
O1. 3. The queued `hilda_c` / solved arm (prices the constants batch alone; ~5 h Torch) — still wanted?
