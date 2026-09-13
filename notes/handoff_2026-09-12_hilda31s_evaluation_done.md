# Handoff — 2026-09-12. **THE FULL EVALUATION OF `hilda31s` IS DONE** (`notes/assessment_2026-09-12_hilda31s.md`; CHANGELOG 2026-09-12; memory [[ccx_assessment_20260912]]). **Verdict: NOT YET ACCEPTABLE — the seasonal mixed layer moved the seasonal link and nothing on the release blocker (the ENSO ocean sign).** Two evaluation-machinery defects were found and fixed. NOTHING ADOPTED. Next: N → A's unrefitted probe → C′ on Torch → M.

> Self-contained. Read the assessment note §1–§4 for every number; `INDEX_ccx.md` (live line updated), `INDEX_ccx_gates.md`
> (the 09-12 ledger line), `INDEX_ccx_seas.md` (GATE S), `INDEX_conv.md` (two new rules). Previous handoff: `handoff_2026-09-11c_…`.

## 1. WHAT THIS SESSION DID (CarbonCycleEmulator, one commit)
| step | outcome |
|---|---|
| scorecard re-pointed | `calibration/diag_whole_model_scorecard.R`: arms `ent26` (path) / `hilda31p` (by name, `CCX_MODE_SEASML0_CONTROL`) / `hilda31s`; + GL, P7, L; + §0 reproduction guard. 16 s. → `outputs/diagnostics/whole_model_scorecard_20260911.{log,rds}` (tag = launch date) |
| ⛔ FOUND + FIXED | every gate spun arms up ASEASONALLY (`ccx_spinup()` in `dg_run`/`dg_gateG`/`dg_gateL_partition`/IRF); `hilda31s` read −3889.6 vs stored −1442.4. `dg_vector()` records the file's spinup; `dg_spinup(v)` everywhere. GATE Q's 2.42 (09-11 (8)) was that read; on-mode 2.63 |
| ⛔ FOUND + FIXED | GATE S's knockout blind to the third limb: 0.410 @ 4.53 FAIL vs whole limb 0.465 @ 8.96 PASS (hemisphere-clean 0.451 @ 9.41). `SL_CASES$SH_ocean` += `seas_ml = 0`; `test-gate-bounds` +5 (names + power), mutation-tested |
| the note | 09-08 five-part form; options re-ranked: **A** (Niño3.4 limb, option B ruling 2) first, **C′** (pin the shim to 0), **M** (per-hemisphere MLD handle), **K** (gate thermal:DIC ratio; needs a SOURCE), D, B, E; **I retired** (GATE 5 passes), G built (GL) |
| tests | gate-bounds 178, alpha-as pre-existing red pair (6.2 vs 3 × 2.63), gate-p7 25, mode-struct-lint 5, seasonal-box-observable 15. **Full suite NOT re-run** — run it first next session |

## 2. NEXT (in order; each is a session or less)
1. **Suite first** (expect the pre-existing pair; `test-gate-bounds` now runs the model twice more).
2. **N** — arbitrate the two ENSO estimators (`diag_gateS_indep_and_fixB.R` PART B −0.432 vs the scorecard −0.522 at `ent26`): same arm, diff the annualisation/window/detrend. An hour.
3. **A's UNREFITTED probe** at `hilda31s` (prereg first): scale the interior → ML exchange by (1 − γ·Niño3.4), γ ≥ 0; does the solubility-only r flip from −0.525 to ≥ +0.3 at the γ the +55 µatm reservoir implies ([[ccx_fixB_reservoir_priced]])? This decides whether the limb suffices or the box is needed.
4. **C′** concurrently on Torch: `hilda31s` refit with `ent_seas_amp_SH` pinned to 0 (`seas_ml` 1). Read GATE S (must pass), `co2/d13c_seasonal_SPO` (≤ 1 log-unit each), the thermal:DIC anatomy before/after. ⚠ Reference set: add `hilda31s`; regenerate `port_targets.csv` at `seas_ml` 1 (handoff 09-11c §4).
5. **M** — a per-hemisphere knockout handle on the MLD cycle (zero one hemisphere's harmonics in `ccx_prepare`, R + C++ parity); then re-read GATE S hemisphere-clean through it (the override read 0.451 @ 9.41 must reproduce) and complete the 27q decomposition (`NH_origin` + the NH ML).

## 3. NON-OBVIOUS STATE
- ⚠ **`dg_vector()` vectors now carry `$spinup`/`$spinup_label`; a hand-built vector (no field) is spun up ASEASONALLY** — as every pre-09-09x vector meant. Any diagnostic that builds `v` by hand for a periodic-fitted mode must set `v$spinup <- ccx_periodic_spinup` or it reads off-mode.
- ⚠ **`SL_CASES$SH_ocean` now switches `seas_ml` off — for BOTH hemispheres.** At a `seas_ml` 0 arm it is a no-op (the three consuming diagnostics are unchanged). `NH_origin` does NOT include the NH mixed layer.
- ⚠ The 09-11c handoff's "ML DIC cycle ±40 µmol/kg" does not reproduce: ±13 (NH max Feb / SH max Aug) under the annual-mean reader.
- ⚠ `R/model.R` `ccx_seas_ml_on()` comment still says "which is why no periodic spinup is needed" — stale since 09-09x (option J).
- `dg_gateG`'s 1750 surface value is now the first output year's annual mean (reported only).
- Torch queue: nothing launched this session.

## 4. ⛔ WHAT I WOULD NOT DO
- Quote any gate number for a periodic-fitted mode from a script that still calls `ccx_spinup()` directly (grep before trusting: `grep -n "ccx_spinup(" calibration/*.R`).
- Build option B before A's probe has an answer; adopt K without its source.
- Read GATE S at `seas_ml` 1 with a knockout that omits the switch, or quote the hemisphere-clean number as the gate's (it is an override read until M).

## POST-SCRIPT (later 09-12): the review's seven rulings are IMPLEMENTED (CHANGELOG 09-12 (b), (c); commits `b6ab0a9`, `60a0f01`, `917964b`)
- ENSO forcing tapers to zero past the record (7.0-mo e-folding from its own ACF). Gate re-cuts: Q annual mean + area weights (**2.89**), H/GL on the residual sd (**+11.6 / −10.1**; the CO₂ control is −3.6 se — its "passes" claim withdrawn), 5's lag on the first-peak time (**+1.72**), the gate run to 2025 (`DG_SINK_LAST`).
- ⛔ **THE OBJECTIVE MOVED and both registered files are RESTAMPED: `hilda31s` −1453.361237, `hilda31p` −1456.210225** (annual-mean isotope pins; the reader on the model's rows; IntCal ends 1941). Demean price 43.91 → **32.55**. **A REFIT IS OWED** — `hilda31s` is the mode of yesterday's objective; the δ¹³C level rows moved −17/+8 at it. Next Torch array: reference set + `hilda31s`, `port_targets.csv` at `seas_ml` 1, and read the level rows first.
- §2's order stands (suite → N is RESOLVED → A's probe → C′ → M), with the refit now FIRST if a Torch slot is free — C′ can ride in the same array (pin `ent_seas_amp_SH` to 0 as a second arm).
- Still unapplied from the review: A10/A15 test repairs, B4 suite fixtures, B1–B3 objective/derivative overhead, the doc rot (§C), A12's partial-year edge months, A14 (the MCMC driver's base params).

## POST-SCRIPT 2 (late 09-12): ROUND 7 IS RUNNING — job `17490222` on Torch (CHANGELOG 09-12 (e))
24 starts at %24 on `cs`, all running on cs700 at submission; preflight `17490208` 8/8 clean, port gate rel ≤ 4.5e−9. References `hilda31s` (id 1) / `hilda31p` (id 2, −1567.99 at seas_ml 1). Outdir `multistart_20260912_round7_seasml1_sd1.0452`. **Next session: `squeue -u ms17839`; when drained, `collect_dispersed_multistart.R` on the outdir; compare on LIKELIHOOD vs the restamped `hilda31s` (−1399.2047 common rows); δ¹³C level rows first; promotion is a ruling.** The review's remaining items are all applied (09-12 (d)); the HILDA blocks consolidated; the two ice diagnostics converted.

## POST-SCRIPT 3 (2026-09-13): `hilda31s2` ADOPTED (CHANGELOG 09-13; `9bc7031` +)
Round 7 promoted (id 1), Hessian PD cond 3.36e5 (h_ml 64.82 ± 2.43), repointed. `hilda31s` retired + quarantined (`CCX_MODE_HILDA31S_QUARANTINED`); `hilda31p` the control. Demean 42.5817. Scorecard 09-13: the chain unchanged (Q 2.88, H +11.6, ENSO r −0.528). **Next: C′ (`ent_seas_amp_SH` pinned to 0) as its own array vs `hilda31s2` — reference set is already hilda31s2 / hilda31p; regenerate `port_targets.csv` after any objective change; then A's Niño3.4-limb probe, then M.** Fairshare was 0.20 on 09-12; a 6-h queue wait on `cs` is now the observed cost of an array.

## POST-SCRIPT 4 (2026-09-13 (b)): C′ STAGED — pinned arms exist; preflight `17681611` queued on `cs`
`CCX_MS_PIN=ent_seas_amp_SH=0`; references `hilda31s2` / `hilda31p`; port targets at the pin (incumbent −1526.71). **Next session: `squeue -u ms17839`; when the preflight (ids 0-5,25,45) shows 8/8 COMPLETED and PORT GATE (a) PASSED in the logs, submit the array: `CCX_MS_PIN=ent_seas_amp_SH=0 sbatch --array=0-23%24 calibration/torch/multistart.sbatch`; then collect (`CCX_MS_PIN` set for the collector too — it sources the table), compare on LIKELIHOOD vs `hilda31s2` (−1389.48 common rows), read GATE S and the seasonal SPO rows. Promotion of a pinned arm is a ruling and it would be a PINNED canonical (`CCX_MODE_PINNED`).**

## POST-SCRIPT 5 (2026-09-13 (c)): C′ IS IN — the shim costs 2.5–2.7 likelihood units, all on `d13c_seasonal_SPO`; GATE S passes; `sst_seas_amp_SH` drops 26–31 % under its obs. NOT ADOPTED (a structure ruling). Details CHANGELOG 09-13 (c), memory [[ccx_cprime_result]]. If ruled: round-2 resume of ids 0/1/3/6 (65 m) and 5/10 (73 m, abuts the wall) → promote → pinned canonical. Otherwise next is A's Niño3.4-limb probe (unrefitted, at `hilda31s2`).
