# PREREG (build + probe tier) — O1: the MEAN DEEP RETURN, two arms — the HS-route THC limb (new) and the local STC loop (E's), scanned jointly in RETURN DEPTH × kz with the export PRESCRIBED

**2026-09-15 (d). Written BEFORE any core edit, from HEAD `e85c52d` (the D1 tr-only fix). Implements Marcus's rulings of 09-15 (d)
on `notes/scoping_2026-09-15c_kz_pump_structure.md` §3–4: O1 is the direction ("which option is both consistent with physics and
improves the model" — O1 is the physics; improvement is NOT established, three prior limbs each cost); "do the prereg and the mean
limb, and then the O1 build"; "subducting to level k makes sense if there is a physical mechanism"; **"do both arms"**. T5 / the cell
WAIT for O1; the `hilda_c` / solved arm is DEFERRED. Every number below is read from the tree (the memory files and logs named);
nothing is recalled. `hilda30c` stays canonical; every registered mode stays bit-reproducible; nothing is adopted here.**

## 0. What the probe has to beat, and why no prior result answers it
- Diffusion at the ML base carries 70 % of the bomb ¹⁴C at 1975 (PK-1); kz's hold is SOFT (arm C: −86 at × 0.5, −19 at × 0.7); the
  45-GtC/yr export is a consequence of the solved field demanded by no row; the model has NO advective deep return
  ([[ccx_kz_pump_diagnosis_0915]]).
- Every limb built so far cost: the conveyor / `w_out` z +22 on deep Δ¹⁴C (`INDEX_ccx_ocean_circ`), T-A0 (`w_up`, bottom return)
  −135 with `d14c_profile_bd` −104, E (prescribed export + a 243-Sv loop into layers 1–3) −37.5 like-for-like with kz only × 1.27.
  **All three sank LS MIXED-LAYER water.** D alone at the canonical kz starves the thermocline (−895). No probe has scanned
  return depth × kz JOINTLY with the export prescribed: T-A2 was anomaly-only at fixed kz, T-A0 the bottom only, E fixed at layers 1–3.
- ⚠ The 08-31 "kz is not the lever" pricing ([[ccx_gates_priced]]) is pre-HILDA; a prior on this probe, not its answer.

## 1. The two arms — each with its physical mechanism, each with the depth range where that mechanism exists
**Arm STC (local closure; built — E's loop).** The subtropical cell: mode-water subduction in the gyres, return by equatorial /
coastal upwelling. Sourced in the tree: Meinen, McPhaden & Johnson 2001 (24–30 Sv equatorial upwelling; `data/obs_eq_cell.rds`),
T-A2's GLODAP read (EUC source water at 100–200 m = layers 2–3). Implemented as `w_vent` with **`k_e1 = k_e2 = k`**, `gamma_vent = 0`
(the mean only). **Physical range k ∈ {1, 2, 3, 4}** (65–435 m at the canonical grid — mode / upper-intermediate water); deeper local
subduction of LS surface water has no mechanism and is NOT scanned.
**Arm THC (HS-route closure; NEW).** The thermohaline / meridional overturning: sinking at the high-latitude surface, entry to the
LS column at the bottom, upward through every interface below the return depth, exit from layer k into the mixed layer, poleward
surface return. Per hemisphere, volume `W_h = w_thc [Sv] × SV × a_hs_h / Σ a_hs`, five legs, EACH `W_h × the source box's
per-volume concentration` (the cell's idiom; D1 closes; a uniform column is a fixed point by construction):
  1. `ml → hs` at `y[ml]/(a_ml · h_ml(t))` (surface poleward transport; the residual ML under eq/tr);
  2. `hs → hd` at `y[hs]/(a_hs · h_hs(t))` (deep-water formation — cold, DIC-rich, ¹⁴C-depleted HS water);
  3. `hd → oc[nl]` at `y[hd]/(a_hs · dz_hd(t))` (the abyss);
  4. `oc[j+1] → oc[j]` for j = k … nl−1 at `y[oc j+1]/(a_ls · dz_{j+1}(t))` (upwelling through every interface BELOW k);
  5. `oc[k] → ml` at `y[oc k]/(a_ls · dz_k(t))` (the return at depth k; k = 1 is the full Munk column).
  Bulk, `alpha13 = 1`, ⛔ no ¹⁴C fractionation; ALL THREE tracers via `add_flux` (the audit's contract). No ENSO modulation (a MEAN
  limb, as ruled). **Physical range k ∈ {1, 2, 3, 4, 6, 8, 10}** (the whole axis: Munk's full-column upwelling at k = 1; the
  thermocline exits T-A2 priced; the deep exits).
  ⚠ Stated, not claimed settled: the LS-interior exit at layer k is the Munk-column assumption (1966); my recollection (uncited in
  the tree) is that Toggweiler & Samuels 1995 and Marshall & Speer 2012 put most of the real deep return in the Southern Ocean,
  which in this model is the HS box — a return that already exists as the `u_hs` / `q` EXCHANGE. The THC limb's k = 10 exit (into
  the bottom layer, then to the ML) is the nearest built analogue and is in the grid.
**Overlap risk, stated with its check.** The HILDA HD↔interior exchange `q` (`tau_q` 538) and `u_hs` are ALREADY the model's
high-latitude ventilation; the THC limb adds an ADVECTIVE path beside them. In the unrefitted probe both stay at the canonical
values, so every THC point is read against the canonical ventilation, not a refitted one. A refit would trade them — the array's
question, not this probe's.

## 2. What is built (arm THC), and its contracts — P0 (all tested in `tests/testthat/test-thc-limb.R` before any probe number)
**Names.** `w_thc = 0` (Sv, both hemispheres, split by a_hs; table entry logit [0, 60], **flat** prior — ⚠ PRIOR SOURCE OWED before
any array frees it, the `w_vent` precedent; init 20), `k_thc = 1L` (return layer, 1-BASED; STRUCTURAL, not fitted, on `p` not in the
table — the `k_e1` precedent). Prefix check: no existing param or aux name begins with `w_thc` / `k_thc` / `thc_` and neither is a
prefix of one (`w_up`, `w_out_*`, `w_eq`, `w_vent`, `k_w`, `k_eq`, `k_e1/2` checked). Absence = 0 = OFF.
**Aux.** `thc_on = hs_on && pump_field == "martin" && w_thc > 0` (integer; ONE resolver, marshalled), `k_thc`, `thc_share[2] =
a_hs_h / Σ a_hs`. Under `"solved"` the limb is INERT (E's contract: the solved field is diffusion's fixed point, not an advective
one); `w_thc > 0` with `hs_frac = 0` ERRORS by name (no HS box to route through); `k_thc` outside 1..nl errors by name; `w_thc`
non-finite / negative errors by name. `ccx_pump_field_inert("solved")` gains `w_thc`; `CCX_PARAM_ABSENT_OK` gains `w_thc`;
`ccx_migrate_par_set()` fills 0; `ccx_seed_unencodable()` seeds at init (0 is on the logit floor).
**Stability.** `ccx_thc_eigbound(p, grid) = 2 × max( W_h/(a_ml h_ml), W_h/(a_hs h_hs), W_h/(a_hs dz_hd), max_{j≥k} W_h/(a_ls dz_j) )`
at both seasonal extremes; exactly 0 at `w_thc = 0` (so substep counts, hence every registered trajectory, are unchanged).
**Spinup.** No change; the periodic spinup is the objective's. A Newton that fails to converge with the limb on is a FINDING.
**P0a NO-OP:** `w_thc` absent vs present-at-0 — `expect_identical` on spinup `y`, `ccx_deriv`, `ccx_run_fast` state/out; the
canonical's 25 stored streams reproduce bit-exact under its pins. **P0b CONSERVATION:** closed system, HS + martin + THC on, at
`seas_ml` 0 and 1, Σ dC/dt ~ 1e-10 (and ¹³C, ¹⁴C-with-decay). **P0c FIXED POINT:** a uniform column (ml, oc, hs, hd at one
concentration, transport isolated) has zero ocean tendency with the limb on at every k, both cores; POWER: HS 10 % richer moves it.
**P0d PARITY:** R vs C++ derivative 1e-10 and transient 1e-12 at k ∈ {1, 5, 10}, `seas_ml` 0 and 1; "mutate `p` after
`ccx_prepare()`" (the 09-09t class). **P0e VOLUME:** at every box the limb's volume in = out (read off the recorded fluxes at
uniform conc: each box's net = 0 to 1e-12) and the limb MOVES the state at w_thc > 0. **P0f MUTATIONS:** every guard by name; the
eigbound scales with w_thc; k_thc changes the answer; sign flip (a leg reversed) breaks P0c.

## 3. The probe — `calibration/diag_o1_deep_return_scan.R`, unrefitted at `hilda30c`, C++ objective under the file's pins
**Common to every point:** `pump_field = "martin"`, `pump_export = 9.08` (Nowicki's LS median, `data/obs_pump_export_prior.rds`),
`gamma_vent = 0`, `gamma_enso_ocn_* = 0` (inert under martin anyway), every other name at the canonical vector; kz × f with
**f ∈ {1, 0.7, 0.5, 0.35, 0.2}** (0.2 ≈ 2,200 m²/yr, where the SOLVED field's export would reach the observed 5–13; PK-2). HARNESS
GATE: the rebuilt logpost reproduces the stored one within 1e-4 at the canonical (solved) vector, and the martin/k=any/W=0 point
equals the martin/W=0 point of the 09-14 h probe (D alone) to 1e-6 — the limb at 0 is E's D.
**Grid.** STC: k ∈ {1,2,3,4} × W ∈ {10, 20, 40 Sv} × f (60 points). THC: k ∈ {1,2,3,4,6,8,10} × W ∈ {10, 20, 30 Sv} × f (105 points).
CONTROL: the canonical STRUCTURE (solved field, no limb) × f — arm A's raw numbers already exist (PK-2) and are re-read here for
the same f grid so the control is like-for-like on this script's harness (f = 0.2 is new).
**Stages.** (1) RAW: every point, one C++ run, the 25 rows and the diagnostics (below). (2) ARM C: for each arm and each k, the
(W, f) point with the best raw like-for-like is re-optimised over arm C's names `{beta_max, fert_k, q10, kz_deep_frac, h_ml, k_w,
bomb_total, sigma_d14c}` (Nelder–Mead 1500 + BFGS 100, the PK-2 machinery); the CONTROL is re-optimised the same way at the same
f (PK-2 has × 0.5 / 0.7; × 0.35 / 0.2 are run here). Selection by raw score is PART OF THE PROCEDURE and stated; no point is
chosen after reading stage 2. (3) The best THC point additionally at `tau_q × {0.5, 2}` (the overlap check, two runs).
**Reads per point** (all from `dg_run`): the 25-row Δlik vs the canonical; `excess_c14_ocean` and the 1975/1995 ocean bomb
excess in kmol; `ocean_grad_dic` (the modern surface–deep gradient) and its z; `d14c_profile_{level,ab,bd}`; `d14c_NH/SH`;
`gcb_ocean_sink` (2015–2023); the CO₂ level rows; the PI layer-wise DIC profile minus the ML (the inversion read of N-E1); the
kmol of bomb ¹⁴C delivered by each pathway at 1975 / 1995 (the PK-1 recorder, R path, at the best point per arm only — it costs 194 s).

## 4. Predictions and the decision rule — observational first, ordering second, nothing model-invented
- **P1 (the limb is not inert where kz falls).** At f ≤ 0.5, |Δlik| between W = 0 and W = 20 Sv exceeds 5 log-units for THC at
  k ≥ 4 and for STC at k ≤ 3 (E's 0.065 /yr-vs-3 /yr reading says inertness was kz's doing, not the loop's).
- **P2 (return depth matters, and in T-A2's direction).** Within THC at fixed (W, f), the CO₂ level rows are monotone in k with the
  deep exits paying more (T-A2: −14 / −52 / −59 at k 4 / 6 / bottom for the anomaly limb).
- **P3 (the deep Δ¹⁴C bill is smaller than every LS-sourced limb's).** THC at k = 1, W = 20, f = 1 costs less than T-A0's −135 on
  `d14c_profile_bd` (−104) — the SAME return geometry with HS water instead of ML water is the only difference. If it does not,
  the "HS water is the right end-member" premise is refuted at this ventilation.
- **THE DECISION RULE (O1 goes to the build tier / array only if ALL hold at some stage-2 point):**
  (a) OBSERVATION — `excess_c14_ocean` inside its own σ: the 1995 ocean bomb excess within 51.4 ± 10.8 kmol (Peacock + Key;
      the canonical is at 82.8, z +2.9);
  (b) OBSERVATION — `ocean_grad_dic` inside its own σ: 233 ± 25.2 µmol/kg (the canonical 302.9, z +2.8; the E mode 346.6);
  (c) ORDERING — at the same f, the stage-2 (arm C) score of the new structure ≥ the stage-2 score of the CONTROL (the canonical
      structure under the same re-optimisation at the same kz: −86 at × 0.5, −19 at × 0.7 from PK-2; × 0.35 / 0.2 run here).
      This is the like-for-like "does the structure do at least as well as the canonical's soft kz hold", not a number I chose;
  (d) OBSERVATION — the export is Nowicki's 9.08 by construction (prescribed), and the PI layer-2 DIC is NOT inverted below the
      ML (the E mode's −66 µmol/kg was real and disqualifying; the read is on the annual mean of the mass-at-the-time reader
      where one exists, else the y-based profile with the winter-ML caveat stated).
  If (a)–(d) hold for exactly one arm, that arm goes to the build tier. If both, the arm with the physical mechanism at its
  passing k (STC k ≤ 4, THC any) and the smaller stage-2 cost; a tie is Marcus's. If neither, **O1 is refuted as built** and O2
  (document) is the honest end state — reported, not patched.
- **Not claimed:** that any point beats the canonical's like-for-like at f = 1 (the E result says the prescribed export costs at the
  old kz); that the STC arm's inertness at E's k = 1–3 carries to k = 4; that `tau_q` stays at 538 under a refit; that 9.08 is the
  right export for THIS column (Nowicki's euphotic depth is 67.6 m vs `h_ml` 65.2 — stated in the E4 ruling).

## 5. The build tier that follows a PASS (the O1 build — a second, short prereg after the read, not now)
A structure label `hilda_o1` (= `hilda_c` + `pump_field = "martin"` + the passing arm's limb with its k as a structural
constant), `w_thc` (or `w_vent`) and `pump_export` free with the arm-C names and every canonical name but the pins; port targets
regenerated (⚠ `port_targets.csv` is still the E arm's); the launch kit; a Torch array (~5 h). The prior on `w_thc` is owed before
that array (an OBSERVED overturning strength with a bracket, computed from a data release, the E4 standard). Nothing here decides
the array; the probe does.
